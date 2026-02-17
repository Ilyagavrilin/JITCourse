package org.bench;

public class NativeLib {

    static {
        System.loadLibrary("nativebench");
    }

    public static native double sinLoop(double[] data);

    public static native double sumLoop(double[] data);

    public static native double noopLoop(double[] data);
}
