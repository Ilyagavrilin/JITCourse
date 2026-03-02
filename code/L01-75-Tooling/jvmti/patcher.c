#include <jvmti.h>
#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static jvmtiIterationControl JNICALL
heap_callback(jlong class_tag, jlong size, jlong* tag_ptr, void* user_data) {
    *tag_ptr = 1;
    return JVMTI_ITERATION_CONTINUE;
}

JNIEXPORT jint JNICALL Agent_OnAttach(JavaVM* vm, char* options, void* reserved) {

    srand(time(NULL));

    jvmtiEnv* jvmti = NULL;
    JNIEnv* env = NULL;

    if ((*vm)->GetEnv(vm, (void**)&jvmti, JVMTI_VERSION_1_2) != JNI_OK)
        return JNI_ERR;

    if ((*vm)->GetEnv(vm, (void**)&env, JNI_VERSION_1_8) != JNI_OK)
        return JNI_ERR;

    jvmtiCapabilities caps = {0};
    caps.can_tag_objects = 1;
    (*jvmti)->AddCapabilities(jvmti, &caps);

    // make for now color - random
    int r = rand() % 256;
    int g = rand() % 256;
    int b = rand() % 256;

    printf("Generated color: R=%d G=%d B=%d\n", r, g, b);

    jclass componentClass = (*env)->FindClass(env, "javax/swing/JComponent");
    if (componentClass == NULL) return JNI_ERR;

    jclass colorClass = (*env)->FindClass(env, "java/awt/Color");
    if (colorClass == NULL) return JNI_ERR;

    jmethodID colorCtor = (*env)->GetMethodID(env, colorClass, "<init>", "(III)V");
    if (colorCtor == NULL) return JNI_ERR;

    jobject randomColor = (*env)->NewObject(env, colorClass, colorCtor, r, g, b);

    jmethodID setBg = (*env)->GetMethodID(env, componentClass,
                                          "setBackground",
                                          "(Ljava/awt/Color;)V");

    jmethodID repaint = (*env)->GetMethodID(env, componentClass,
                                            "repaint", "()V");

    if (setBg == NULL || repaint == NULL)
        return JNI_ERR;

    (*jvmti)->IterateOverInstancesOfClass(
        jvmti,
        componentClass,
        JVMTI_HEAP_OBJECT_EITHER,
        heap_callback,
        NULL);

    jlong tag = 1;
    jint count = 0;
    jobject* objects = NULL;

    (*jvmti)->GetObjectsWithTags(
        jvmti,
        1,
        &tag,
        &count,
        &objects,
        NULL);

    for (int i = 0; i < count; i++) {
        (*env)->CallVoidMethod(env, objects[i], setBg, randomColor);
        (*env)->CallVoidMethod(env, objects[i], repaint);
    }

    if (objects != NULL) {
        (*jvmti)->Deallocate(jvmti, (unsigned char*)objects);
    }

    printf("Components recolored: %d\n", count);

    return JNI_OK;
}
