
private void test_markup_base () {
    GI.Repository.get_default().require ("GObject", null, 0);

    const string xml =
    """
    <root type="GObject.Object"/>
    """;

    Gongbang.Graph graph = Gongbang.Markup.load_string (xml);

    // Tests graph.
    assert (graph.n_nodes == 1);

    Gongbang.NodeStruct? node = graph[1] as Gongbang.NodeStruct;

    assert (node != null);
    assert (node.type == typeof (Object));
}

private void test_markup_string () {
    GI.Repository.get_default().require ("GLib", null, 0);
    GI.Repository.get_default().require ("GObject", null, 0);

    const string xml =
    """
    <root type="gchararray">A string.</root>
    """;

    Gongbang.Graph graph = Gongbang.Markup.load_string (xml);

    // Tests graph.
    assert (graph.n_nodes == 1);

    Gongbang.NodeValue? node = graph[1] as Gongbang.NodeValue;

    assert (node != null);
    assert (node.value.get_string() == "A string.");
}

private void test_markup_variant () {
    GI.Repository.get_default().require ("GLib", null, 0);
    GI.Repository.get_default().require ("GObject", null, 0);

    const string xml =
    """
    <root type="GVariant">
        [1, 2, 3]
    </root>
    """;

    Gongbang.Graph graph = Gongbang.Markup.load_string (xml);

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

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/gongbang/markup/base", test_markup_base);
    Test.add_func ("/gongbang/markup/text/string", test_markup_string);
    Test.add_func ("/gongbang/markup/text/variant", test_markup_variant);

    return Test.run ();
}
