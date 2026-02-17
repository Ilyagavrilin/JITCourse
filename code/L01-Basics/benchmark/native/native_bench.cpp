/*
 * native_bench.cpp — simple example of JNI library.
 *
 * License: MIT — free to use, modify, and distribute. No warranty.
 */

#include <jni.h>
#include <cmath>

extern "C" {

JNIEXPORT jdouble JNICALL
Java_org_bench_NativeLib_sinLoop(JNIEnv *env, jclass, jdoubleArray arr) {
    jsize len = env->GetArrayLength(arr);
    jdouble* data = env->GetDoubleArrayElements(arr, nullptr);
    double sum = 0;
    for (int i = 0; i < len; i++)
        sum += std::sin(data[i]);
    env->ReleaseDoubleArrayElements(arr, data, 0);
    return sum;
}

JNIEXPORT jdouble JNICALL
Java_org_bench_NativeLib_sumLoop(JNIEnv *env, jclass, jdoubleArray arr) {
    jsize len = env->GetArrayLength(arr);
    jdouble* data = env->GetDoubleArrayElements(arr, nullptr);
    double sum = 0;
    for (int i = 0; i < len; i++)
        sum += data[i];
    env->ReleaseDoubleArrayElements(arr, data, 0);
    return sum;
}

JNIEXPORT jdouble JNICALL
Java_org_bench_NativeLib_noopLoop(JNIEnv *env, jclass, jdoubleArray arr) {
    jsize len = env->GetArrayLength(arr);
    jdouble* data = env->GetDoubleArrayElements(arr, nullptr);
    for (int i = 0; i < len; i++)
        asm volatile("" : : "r"(data[i]) : );
    env->ReleaseDoubleArrayElements(arr, data, 0);
    return 3.14f;
}

}
