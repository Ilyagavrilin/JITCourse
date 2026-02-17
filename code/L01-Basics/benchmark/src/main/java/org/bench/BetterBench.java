/*
 * BetterBench — JMH benchmark for Java and native sin implementations.
 * Ref: test/micro/org/openjdk/bench/java/math/FpRoundingBenchmark.java
 *
 * License: MIT — free to use, modify, distribute. No warranty.
 */

package org.bench;

import java.util.Random;
import java.util.concurrent.TimeUnit;
import org.openjdk.jmh.annotations.*;

@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(2)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class BetterBench {

    @Param({ "2048" })
    public int TESTSIZE;

    @Param({ "1", "1024" })
    public int RANDOM_COUNT;

    public double[] input;
    public double[] constInput;
    public double[] mixedInput;

    public double[] result;

    @Setup(Level.Trial)
    public void setup() {
        Random r = new Random(12345);

        input = new double[TESTSIZE];
        constInput = new double[TESTSIZE];
        mixedInput = new double[TESTSIZE];
        result = new double[TESTSIZE];

        double[] specials = {
            0.0,
            -0.0,
            Double.NaN,
            Double.POSITIVE_INFINITY,
            Double.NEGATIVE_INFINITY,
            Double.MAX_VALUE,
            -Double.MAX_VALUE,
            Double.MIN_VALUE,
            -Double.MIN_VALUE,
            Math.PI,
            -Math.PI,
        };

        int i = 0;
        for (; i < specials.length && i < TESTSIZE; i++) input[i] = specials[i];

        for (; i < TESTSIZE; i++) input[i] = Double.longBitsToDouble(
            r.nextLong()
        );

        double base = Math.PI / 6.0;
        for (i = 0; i < TESTSIZE; i++) {
            constInput[i] = base;
            mixedInput[i] = base;
        }

        int limit = Math.min(RANDOM_COUNT, TESTSIZE);

        int[] idx = new int[TESTSIZE];
        for (i = 0; i < TESTSIZE; i++) idx[i] = i;

        for (i = TESTSIZE - 1; i > 0; i--) {
            int j = r.nextInt(i + 1);
            int t = idx[i];
            idx[i] = idx[j];
            idx[j] = t;
        }

        for (i = 0; i < limit; i++) {
            int pos = idx[i];
            mixedInput[pos] = Double.longBitsToDouble(r.nextLong());
        }
    }

    @Benchmark
    public void javaMathSin() {
        for (int i = 0; i < TESTSIZE; i++) {
            result[i] = Math.sin(input[i]);
        }
    }

    @Benchmark
    public void javaStrictMathSin() {
        for (int i = 0; i < TESTSIZE; i++) {
            result[i] = StrictMath.sin(input[i]);
        }
    }

    @Benchmark
    public double nativeSin() {
        return NativeLib.sinLoop(input);
    }

    @Benchmark
    public void javaMathSinSame() {
        for (int i = 0; i < TESTSIZE; i++) {
            result[i] = Math.sin(constInput[i]);
        }
    }

    @Benchmark
    public void javaMathSinMixed() {
        for (int i = 0; i < TESTSIZE; i++) {
            result[i] = Math.sin(mixedInput[i]);
        }
    }

    @Benchmark
    public void javaStrictMathSinSame() {
        for (int i = 0; i < TESTSIZE; i++) {
            result[i] = StrictMath.sin(constInput[i]);
        }
    }

    @Benchmark
    public void javaStrictMathSinMixed() {
        for (int i = 0; i < TESTSIZE; i++) {
            result[i] = StrictMath.sin(mixedInput[i]);
        }
    }

    @Benchmark
    @BenchmarkMode(Mode.AverageTime)
    @OutputTimeUnit(TimeUnit.MILLISECONDS)
    public double nativeNoop() {
        return NativeLib.noopLoop(input);
    }
}
