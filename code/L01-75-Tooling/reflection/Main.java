import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.lang.reflect.Field;

public class Main {

    public static void main(String[] args) throws Exception {

        FileInputStream fis = new FileInputStream("Main.java");

        Field fdField = FileDescriptor.class.getDeclaredField("fd");
        fdField.setAccessible(true);

        int rawFd = fdField.getInt(fis.getFD());

        System.out.println("Raw file descriptor: " + rawFd);
    }
}
