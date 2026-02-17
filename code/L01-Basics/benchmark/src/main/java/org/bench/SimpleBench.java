/*
 * SimpleBench — Naive JMH benchmark for Java and native sin.
 * Ref: test/micro/org/openjdk/bench/java/lang/StrictMathBench.java
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
public class SimpleBench {

    public double double1 = Math.PI / 6.0;

    @Benchmark
    public double javaMathSin() {
        return Math.sin(double1);
    }

    @Benchmark
    public double javaStrictMathSin() {
        return StrictMath.sin(double1);
    }
}
