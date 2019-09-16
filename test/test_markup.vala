
private void test_markup_base () {
    try {
        const string xml =
        """
        <gongbang>
          <element type="GObject.Object"/>
        </gongbang>
        """;

        Gongbang.Graph graph = Gongbang.Markup.load_string (xml);

        // Tests graph.
        assert (graph.n_nodes == 1);

        Gongbang.NodeStruct? node = graph[1] as Gongbang.NodeStruct;

        assert (node != null);
        assert (node.type == typeof (Object));
    }
    catch (Error e) {
        critical ("%s", e.message);
        return;
    }
}

private void test_markup_string () {
    try {
        const string xml =
        """
        <gongbang>
          <element type="gchararray">A string.</element>
        </gongbang>
        """;

        Gongbang.Graph graph;

        graph = Gongbang.Markup.load_string (xml);

        // Tests graph.
        assert (graph.n_nodes == 1);

        Gongbang.NodeValue? node = graph[1] as Gongbang.NodeValue;

        assert (node != null);
        assert (node.value.get_string() == "A string.");
    }
    catch (Error e) {
        critical ("%s", e.message);
        return;
    }
}

private void test_markup_variant () {
    try {
        const string xml =
        """
        <gongbang>
          <element type="GVariant">
              [1, 2, 3]
          </element>
        </gongbang>
        """;

        Gongbang.Graph graph;
        graph = Gongbang.Markup.load_string (xml);
        // Tests graph.
        assert (graph.n_nodes == 1);

        Gongbang.NodeValue? node = graph[1] as Gongbang.NodeValue;

        assert (node != null);
        Variant variant = (Variant) node.value;

        assert (variant.is_of_type(new VariantType("ai")));

        VariantIter vi = variant.iterator();
        int element;
        assert (vi.next ("i", out element));
        assert (element == 1);
        assert (vi.next ("i", out element));
        assert (element == 2);
        assert (vi.next ("i", out element));
        assert (element == 3);
    }
    catch (Error e) {
        critical ("%s", e.message);
        return;
    }
}

private void test_markup_integer () {
    try {
        const string xml =
        """
        <gongbang>
          <element type="gint">42</element>
        </gongbang>
        """;

        Gongbang.Graph graph;
        graph = Gongbang.Markup.load_string (xml);

        // Tests graph.
        assert (graph.n_nodes == 1);
        Gongbang.NodeValue? node = graph[1] as Gongbang.NodeValue;

        assert (node != null);
        int number = (int) node.value;

        assert (number == 42);
    }
    catch (Error e) {
        critical ("%s", e.message);
        return;
    }
}

private void test_markup_float () {
    try {
        const string xml =
        """
        <gongbang>
          <element type="gfloat">3.14</element>
        </gongbang>
        """;

        Gongbang.Graph graph;
        graph = Gongbang.Markup.load_string (xml);

        // Tests graph.
        assert (graph.n_nodes == 1);
        Gongbang.NodeValue? node = graph[1] as Gongbang.NodeValue;

        assert (node != null);
        float number = (float) node.value;

        assert (number == 3.14f);
    }
    catch (Error e) {
        critical ("%s", e.message);
        return;
    }
}

private void test_markup_file () {
    try {

        // Gongbang does not require Gio automatically
        const string xml =
        """
        <gongbang>
          <require>Gio</require>
          <element type="Gio.File">unicorn.txt</element>
        </gongbang>
        """;

        Gongbang.Graph graph;
        graph = Gongbang.Markup.load_string (xml);

        // Test graph.
        assert (graph.n_nodes == 1);
        Gongbang.NodeValue? node = graph[1] as Gongbang.NodeValue;

        assert (node != null);
        File? file = (File?) node.value;

        assert (file.get_basename() == "unicorn.txt");
    }
    catch (Error e) {
        critical ("%s", e.message);
        return;
    }
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/gongbang/markup/base", test_markup_base);
    Test.add_func ("/gongbang/markup/text/string", test_markup_string);
    Test.add_func ("/gongbang/markup/text/variant", test_markup_variant);
    Test.add_func ("/gongbang/markup/text/integer", test_markup_integer);
    Test.add_func ("/gongbang/markup/text/float", test_markup_float);
    Test.add_func ("/gongbang/markup/text/file", test_markup_file);

    return Test.run ();
}
