public class HexDumpTest : TestCase {
    public HexDumpTest() {
        base("HexDumpTest");
        add_test("test_example", test_example);
    }

    private void test_example() {
        assert(1 == 1);
    }
}
