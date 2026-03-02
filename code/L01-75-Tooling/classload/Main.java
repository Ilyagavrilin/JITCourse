import java.net.URL;
import java.net.URLClassLoader;
import java.lang.reflect.Method;
import java.io.File;

public class Main {

    public static void main(String[] args) throws Exception {

        File dir = new File("plugins");
        URL url = dir.toURI().toURL();

        try (URLClassLoader loader = new URLClassLoader(new URL[]{url})) {

            Class<?> clazz = loader.loadClass("plugins.HelloPlugin");

            Object instance = clazz.getDeclaredConstructor().newInstance();

            Method method = clazz.getMethod("run");
            method.invoke(instance);
        }
    }
}
