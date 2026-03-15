import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Label;
import org.objectweb.asm.MethodVisitor;

import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.objectweb.asm.Opcodes.*;

public class BytecodeApp {
    public static void main(String[] args) throws Exception {
        byte[] bytes = generate();

        Path outDir = Path.of("generated");
        Files.createDirectories(outDir);
        Path outFile = outDir.resolve("GeneratedGuesses.class");
        Files.write(outFile, bytes);

        Class<?> clazz = new Loader().define(bytes);
        Method guess1 = clazz.getMethod("guess_1", int.class);
        Method guess2 = clazz.getMethod("guess_2", int.class, int.class);

        System.out.println("Wrote: " + outFile.toAbsolutePath());
        System.out.println("guess_1(5) = " + guess1.invoke(null, 5));
        System.out.println("guess_2(48, 18) = " + guess2.invoke(null, 48, 18));
    }

    private static byte[] generate() {
        ClassWriter cw = new ClassWriter(ClassWriter.COMPUTE_FRAMES | ClassWriter.COMPUTE_MAXS);
        cw.visit(V17, ACC_PUBLIC | ACC_SUPER, "GeneratedGuesses", null, "java/lang/Object", null);

        defaultConstructor(cw);
        emitGuess1(cw);
        emitGuess2(cw);

        cw.visitEnd();
        return cw.toByteArray();
    }

    private static void defaultConstructor(ClassWriter cw) {
        MethodVisitor mv = cw.visitMethod(ACC_PUBLIC, "<init>", "()V", null, null);
        mv.visitCode();
        mv.visitVarInsn(ALOAD, 0);
        mv.visitMethodInsn(INVOKESPECIAL, "java/lang/Object", "<init>", "()V", false);
        mv.visitInsn(RETURN);
        mv.visitMaxs(0, 0);
        mv.visitEnd();
    }

    // int guess_1(int n) -> Fibonacci(n)
    private static void emitGuess1(ClassWriter cw) {
        MethodVisitor mv = cw.visitMethod(ACC_PUBLIC | ACC_STATIC, "guess_1", "(I)I", null, null);
        mv.visitCode();

        Label loop = new Label();
        Label done = new Label();

        // if (n <= 1) return n;
        mv.visitVarInsn(ILOAD, 0);
        mv.visitInsn(ICONST_1);
        mv.visitJumpInsn(IF_ICMPGT, loop);
        mv.visitVarInsn(ILOAD, 0);
        mv.visitInsn(IRETURN);

        // int a = 0, b = 1, i = 2;
        mv.visitLabel(loop);
        mv.visitInsn(ICONST_0);
        mv.visitVarInsn(ISTORE, 1);
        mv.visitInsn(ICONST_1);
        mv.visitVarInsn(ISTORE, 2);
        mv.visitInsn(ICONST_2);
        mv.visitVarInsn(ISTORE, 3);

        Label body = new Label();
        Label check = new Label();
        mv.visitJumpInsn(GOTO, check);

        // body: int next = a + b; a = b; b = next; i++;
        mv.visitLabel(body);
        mv.visitVarInsn(ILOAD, 1);
        mv.visitVarInsn(ILOAD, 2);
        mv.visitInsn(IADD);
        mv.visitVarInsn(ISTORE, 4);

        mv.visitVarInsn(ILOAD, 2);
        mv.visitVarInsn(ISTORE, 1);

        mv.visitVarInsn(ILOAD, 4);
        mv.visitVarInsn(ISTORE, 2);

        mv.visitIincInsn(3, 1);

        // while (i <= n)
        mv.visitLabel(check);
        mv.visitVarInsn(ILOAD, 3);
        mv.visitVarInsn(ILOAD, 0);
        mv.visitJumpInsn(IF_ICMPLE, body);

        mv.visitLabel(done);
        mv.visitVarInsn(ILOAD, 2);
        mv.visitInsn(IRETURN);
        mv.visitMaxs(0, 0);
        mv.visitEnd();
    }

    // int guess_2(int a, int b) -> GCD(a, b) via Euclid
    private static void emitGuess2(ClassWriter cw) {
        MethodVisitor mv = cw.visitMethod(ACC_PUBLIC | ACC_STATIC, "guess_2", "(II)I", null, null);
        mv.visitCode();

        Label check = new Label();
        Label body = new Label();

        mv.visitJumpInsn(GOTO, check);

        mv.visitLabel(body);
        // int t = a % b;
        mv.visitVarInsn(ILOAD, 0);
        mv.visitVarInsn(ILOAD, 1);
        mv.visitInsn(IREM);
        mv.visitVarInsn(ISTORE, 2);

        // a = b;
        mv.visitVarInsn(ILOAD, 1);
        mv.visitVarInsn(ISTORE, 0);

        // b = t;
        mv.visitVarInsn(ILOAD, 2);
        mv.visitVarInsn(ISTORE, 1);

        // while (b != 0)
        mv.visitLabel(check);
        mv.visitVarInsn(ILOAD, 1);
        mv.visitJumpInsn(IFNE, body);

        mv.visitVarInsn(ILOAD, 0);
        mv.visitInsn(IRETURN);
        mv.visitMaxs(0, 0);
        mv.visitEnd();
    }

    private static final class Loader extends ClassLoader {
        Class<?> define(byte[] bytes) {
            return defineClass(null, bytes, 0, bytes.length);
        }
    }
}
