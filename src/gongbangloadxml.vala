using Gongbang;

/**
 * Loading Graph from markup file.
 *
 * A typical markup file would look like.
 *
 * {{{
 * <gongbang>
 *   <require>Dungeon</require>
 *   <element type="Dungeon.SkeletonWarrior">
 *     <level>13</level>
 *     <weapon type="Dungeon.Sword"/>
 *   </element>
 * </gongbang>
 * }}}
 *
 *
 * === Top levels ===
 *
 * Name of the root element is "gongbang"
 *
 *  * gongbang
 *    * require (*)
 *    * element (*)
 *
 * ==== require ====
 *
 * Attributes:
 *
 *  * private_dir: path, optional: A private path to look for typelib file.
 *  * version: string, optional: Version to require.
 *
 * Contents:
 *
 *  * (text): string: Typelib namespace to require.
 *
 * "require" element denotes this file mentions types from the namespace.
 * Any type may be used, after the corresponding namespaces are required.
 *
 * ==== element ====
 *
 * Attributes:
 *
 *  * type: type: A type of element
 *  * name: string: Name of element to reference on other part.
 *
 * This contains values or objects at top level.
 *
 * === Markups for value types. ===
 *
 * ==== Text representations ====
 *
 * It is frequently to have various datas are expressed as texts.
 *
 * ===== Numbers =====
 *
 * BLAH!
 *
 * ===== GLib.Variant =====
 *
 * Variant types are processed with {@link GLib.Variant.parse} function.
 *
 * ===== Gio.File =====
 *
 * Files are denoted as paths.
 *
 */
namespace Gongbang.Markup {
    /**
     * Loads Graph from markup.
     */
    public Graph load (InputStream stream, Cancellable? cancel = null) throws IOError, MarkupError {
        uint8[] buffer = new uint8[4096];
        ssize_t buffer_readsize = 0;

        XMLParse parse = new XMLParse();
        MarkupParseContext ctx = new MarkupParseContext (load_xml_parser,
          MarkupParseFlags.PREFIX_ERROR_POSITION,
          parse, null);

        do {
            buffer_readsize = stream.read(buffer, cancel);
            ctx.parse ((string)buffer, buffer_readsize);
        } while (buffer_readsize != 0);

        ctx.end_parse();
        return parse.graph;
    }

    /**
     * Loads Graph from string.
     *
     * When you have full-loaded string, this would be efficient, as it pushes
     * whole string at once.
     */
    public Graph load_string (string markup) throws MarkupError {
        XMLParse parse = new XMLParse();
        MarkupParseContext ctx = new MarkupParseContext (load_xml_parser,
          MarkupParseFlags.PREFIX_ERROR_POSITION,
          parse, null);
        ctx.parse (markup, -1);
        ctx.end_parse();
        return parse.graph;
    }

    /**
     * Loads Graph from file.
     */
    public Graph load_file (File file, Cancellable? cancel = null) throws Error {
        return load (file.read(cancel), cancel);
    }

    private const MarkupParser load_xml_parser = {
        XMLParse.start_element,
        XMLParse.end_element,
        XMLParse.text,
        null,
        null
    };

    [Compact]
    private class XMLParseElement {
        public GLib.Type type;
        public bool is_text;
        public HashTable<string, int32> subnodes;
        public Value value;

        public XMLParseElement () {
            type = Type.INVALID;
            is_text = false;
            subnodes = new HashTable<string, int32> (string.hash, str_equal);
        }
    }

    /* This will parse either of one form.
     * <some-field type="GObject.Object">
     * </some-field>
     *
     * some literal values.
     */
    [Compact]
    private class XMLParse {
        public Graph graph;
        public Queue<XMLParseElement> elements;

        public XMLParse() {
            graph = new Graph();
            elements = new Queue<XMLParseElement>();
        }

        public void start_element (MarkupParseContext ctx, string name, string[] attr_names, string[] attr_values) throws MarkupError {
            unowned XMLParseElement? parent = elements.peek_tail ();

            if ((parent != null) && (parent.is_text))
                throw new MarkupError.INVALID_CONTENT("Text marked element!");

            unowned string? picked_type_str;

            GLib.Markup.collect_attributes (name, attr_names, attr_values,
                GLib.Markup.CollectType.STRING | GLib.Markup.CollectType.OPTIONAL, "type", out picked_type_str);

            GLib.Type picked_type = parse_type (picked_type_str);


            GI.TypeInfo? parent_constraint = check_name (name);

            XMLParseElement element = new XMLParseElement ();
            element.type = check_type (parent_constraint, picked_type);

            elements.push_tail((owned) element);

        }

        public void end_element (MarkupParseContext ctx, string name) throws MarkupError{
            XMLParseElement? tail = (!) elements.pop_tail();
            Gongbang.Node? node = null;


            if (tail.is_text) {
                node = new Gongbang.NodeValue (tail.value);
            }
            else {
                Gongbang.NodeStruct nstruct = new Gongbang.NodeStruct (tail.type);

                HashTableIter<string, int32> iter = HashTableIter<string, int32> (tail.subnodes);
                unowned string ik;
                int32 iv;
                while (iter.next(out ik, out iv)) nstruct.members[ik] = iv;

                node = (owned) nstruct;
            }

            int32 node_id = graph.add (node);

            // Add subnode for parent.
            // assumes parent type is composite type.
            // as start_element requires parent type to be composite type.
            unowned XMLParseElement? parent = elements.peek_tail();
            if (parent != null)
                parent.subnodes[name] = node_id;
        }

        public void text (MarkupParseContext ctx, string text, size_t text_len) throws MarkupError {
            unowned XMLParseElement tail = (!) elements.peek_tail();
            string actual_text = text.substring (0, (int)text_len).chomp();

            tail.is_text = true;

            if (tail.type == typeof (string)) {
                tail.value = actual_text;
            }
            else if (tail.type == typeof (StringBuilder)) {
                tail.value = new StringBuilder (actual_text);
            }
            else if (tail.type == typeof (Variant)) {
                try {
                    tail.value = Variant.parse (null, actual_text);
                }
                catch (VariantParseError e) {
                    throw new MarkupError.INVALID_CONTENT (
                        "Variant parse failed: %s", e.message);
                }
            }
            else if (tail.type == typeof (Type)) {
                tail.value = parse_type (actual_text);
            }

            else {
                throw new MarkupError.INVALID_CONTENT(
                    "Unsupported types for texts: %s",
                    tail.type.name());
            }
        }


        // Internal logics.

        private GLib.Type parse_type (string? name) throws MarkupError {
            if (name == null) return GLib.Type.INVALID;

            int split_index = ((!)name).index_of_char ('.');
            if (split_index == -1) {
                GLib.Type type = GLib.Type.from_name ((!)name);

                if (type == GLib.Type.INVALID)
                    throw new MarkupError.INVALID_CONTENT("GType not exists: \"%s\"", name);
                return type;
            }
            else {
                string type_ns = name[0:split_index];
                string type_name = name[split_index + 1 : name.length];
                GI.BaseInfo? info = GI.Repository.get_default().find_by_name (type_ns, type_name);

                if (info == null) {
                    throw new MarkupError.INVALID_CONTENT("Type not exists: \"%s\"", name);
                }

                GI.InfoType info_type = ((!)info).get_type();
                switch (info_type) {
                case GI.InfoType.ENUM:
                case GI.InfoType.STRUCT:
                case GI.InfoType.UNION:
                case GI.InfoType.INTERFACE:
                case GI.InfoType.OBJECT:
                    return ((GI.RegisteredTypeInfo)info).get_g_type();
                }
                return typeof (void*);
            }
        }

        private GI.TypeInfo? check_name (string name) throws MarkupError {
            if (elements.is_empty()) {
                if (name != "root")
                    throw new MarkupError.UNKNOWN_ELEMENT("Root element should be \"root\", not \"%s\"", name);

                return null;
            }

            else {
                unowned XMLParseElement tail = (!)elements.peek_tail();
                GI.BaseInfo? compound_info = GI.Repository.get_default().find_by_gtype (tail.type);
                if (compound_info == null) {
                    critical ("compound has no info associated with type \"%s\"", tail.type.name());
                    return null;
                }

                GI.BaseInfo? field_info = info_find_field (compound_info, name);

                if (field_info == null) {
                    throw new MarkupError.UNKNOWN_ELEMENT("Field %s not found, for %s", name, info_full_name (compound_info));
                }

                GI.InfoType field_type = field_info.get_type();

                if (field_type == GI.InfoType.FIELD)
                    return ((GI.FieldInfo)field_info).get_type();

                else if (field_type == GI.InfoType.PROPERTY)
                    return ((GI.PropertyInfo)field_info).get_type();

                else
                    return null;
            }
        }

        private GLib.Type check_type (GI.TypeInfo? info, GLib.Type picked_type = Type.INVALID) throws MarkupError {
            GLib.Type info_type = GLib.Type.INVALID;

            // get info type
            if (info != null) {
                switch (((!)info).get_tag()) {
                case GI.TypeTag.VOID:
                    info_type = typeof (void);
                    break;

                case GI.TypeTag.BOOLEAN:
                    info_type = typeof (bool);
                    break;

                // Unclassed int types
                case GI.TypeTag.INT8:
                case GI.TypeTag.INT16:
                case GI.TypeTag.INT32:
                case GI.TypeTag.INT64:
                    info_type = typeof (int64);
                    break;

                case GI.TypeTag.UINT8:
                case GI.TypeTag.UINT16:
                case GI.TypeTag.UINT32:
                case GI.TypeTag.UINT64:
                    info_type = typeof (uint64);
                    break;

                // Special case: UNICHAR
                case GI.TypeTag.UNICHAR:
                    info_type = typeof (unichar);
                    break;

                // Floating point types
                case GI.TypeTag.FLOAT:
                    info_type = typeof (float);
                    break;

                case GI.TypeTag.DOUBLE:
                    info_type = typeof (float);
                    break;

                // String types.
                case GI.TypeTag.UTF8:
                case GI.TypeTag.FILENAME:
                    info_type = typeof (string);
                    break;

                // Special GLib's types.
                case GI.TypeTag.GTYPE:
                    info_type = typeof (Type);
                    break;

                case GI.TypeTag.ERROR:
                    info_type = typeof (Error);
                    break;

                case GI.TypeTag.GHASH:
                    info_type = typeof (HashTable);
                    break;

                // TODO: Find a way to support pointers properly.
                case GI.TypeTag.GLIST:
                    info_type = typeof (List);
                    break;

                case GI.TypeTag.GSLIST:
                    info_type = typeof (SList);
                    break;

                // Extended types
                case GI.TypeTag.ARRAY:
                    switch (info.get_array_type()) {
                    case GI.ArrayType.C:
                        info_type = typeof (void*);
                        break;

                    case GI.ArrayType.ARRAY:
                        info_type = typeof (GLib.Array);
                        break;

                    case GI.ArrayType.BYTE_ARRAY:
                        info_type = typeof (GLib.ByteArray);
                        break;

                    case GI.ArrayType.PTR_ARRAY:
                        info_type = typeof (GLib.GenericArray);
                        break;
                    }
                    break;

                case GI.TypeTag.INTERFACE:
                    {
                        GI.BaseInfo type_iface = (!) info.get_interface ();
                        GI.InfoType type_iface_tag = type_iface.get_type();

                        switch (type_iface_tag) {
                        case GI.InfoType.ENUM:
                        case GI.InfoType.STRUCT:
                        case GI.InfoType.UNION:
                        case GI.InfoType.INTERFACE:
                        case GI.InfoType.OBJECT:
                            info_type = ((GI.RegisteredTypeInfo)type_iface).get_g_type();
                            break;

                        case GI.InfoType.CALLBACK:
                            info_type = typeof (void*);
                            break;

                        default:
                            info_type = typeof (void*);
                            break;
                        }
                    }
                    break;
                }
            }

            // When type is not specified.
            if (picked_type == GLib.Type.INVALID) {
                if (info_type == GLib.Type.INVALID) {
                    throw new GLib.MarkupError.MISSING_ATTRIBUTE("Missing type");
                }
                else if (info_type.is_abstract()) {
                    throw new GLib.MarkupError.MISSING_ATTRIBUTE("Missing type: Default type \"%s\" is abstract", info_type.name());
                }
                return info_type;
            }

            // When type is specified.
            else {
                if (info_type != GLib.Type.INVALID) {
                    if (! Value.type_transformable (picked_type, info_type)) {
                        throw new GLib.MarkupError.INVALID_CONTENT("Invalid type: Type \"%s\" is not compatible for \"%s\"", picked_type.name(), info_type.name());
                    }
                }
                if (picked_type.is_abstract()) {
                    throw new GLib.MarkupError.INVALID_CONTENT("Invalid type: Type \"%s\" is abstract", picked_type.name());
                }
                return picked_type;
            }
        }
    }

    /*
     *
     */
    private string info_full_name (GI.BaseInfo info) {
        StringBuilder builder = new StringBuilder ();
        info_full_name_recursive (info, builder);
        return builder.str;
    }

    private void info_full_name_recursive (GI.BaseInfo info, StringBuilder builder) {
        GI.BaseInfo? container = info.get_container();

        if (container == null)
            builder.assign (info.get_namespace());
        else
            info_full_name_recursive (container, builder);

        builder.append_c ('.');
        builder.append (info.get_name());
    }

    /*
     * Make hash, from symbol name and namespaces.
     */
    private uint info_hash (GI.BaseInfo info) {
        return info.get_namespace().hash() * 71 + info.get_name().hash();
    }



    private GI.BaseInfo? info_find_field (GI.BaseInfo info, string name) {
        GI.InfoType info_type = info.get_type();

        if (info_type == GI.InfoType.STRUCT)
            return ((GI.StructInfo)info).find_field (name);

        else if (info_type == GI.InfoType.UNION)
            return union_info_find_field ((GI.UnionInfo) info, name);

        GenericSet<GI.BaseInfo> lookup =
            new GenericSet<GI.BaseInfo>(info_hash, GI.BaseInfo.equal);

        if (info_type == GI.InfoType.OBJECT)
            return object_info_find_field ((GI.ObjectInfo) info, name, lookup);

        else if (info_type == GI.InfoType.INTERFACE)
            return iface_info_find_field ((GI.InterfaceInfo) info, name, lookup);

        return null;
    }

    private GI.FieldInfo? union_info_find_field (GI.UnionInfo info, string name) {
        int n = info.get_n_fields ();

        for (int i = 0; i < n; i++) {
            GI.FieldInfo field = info.get_field (i);
            if (field.get_name () == name) return field;
        }
        return null;
    }

    private GI.BaseInfo? object_info_find_field (GI.ObjectInfo info,
                                                 string name,
                                                 GenericSet<GI.BaseInfo> lookup) {
        if (info in lookup) {
            return null;
        }

        lookup.add (info);

        // Prefer properties over fields.
        int n_props = info.get_n_properties ();
        for (int i = 0; i < n_props; i++) {
            GI.PropertyInfo prop = info.get_property (i);
            if (prop.get_name () == name) return prop;
        }

        int n_fields = info.get_n_fields ();
        for (int i = 0; i < n_fields; i++) {
            GI.FieldInfo field = info.get_field (i);
            if (field.get_name () == name) return field;
        }

        // Lookup parents and interfaces.

        GI.BaseInfo? inherited = null;

        GI.ObjectInfo? parent = info.get_parent ();
        if (parent != null)
            inherited = object_info_find_field (parent, name, lookup);

        if (inherited == null) {
            int n_ifaces = info.get_n_interfaces ();
            for (int i = 0; i < n_ifaces; i++) {
                GI.InterfaceInfo iface = info.get_interface (i);
                inherited = iface_info_find_field (iface, name, lookup);

                if (inherited != null) break;
            }
        }

        return inherited;
    }

    private GI.BaseInfo? iface_info_find_field (GI.InterfaceInfo info,
                                                    string name,
                                                    GenericSet<GI.BaseInfo> lookup) {
        if (info in lookup) {
            return null;
        }

        lookup.add (info);

        int n_props = info.get_n_properties ();
        for (int i = 0; i < n_props; i++) {
            GI.PropertyInfo prop = info.get_property (i);
            if (prop.get_name () == name) return prop;
        }

        // Lookup prerequisite types.

        int n_prereqs = info.get_n_prerequisites ();
        for (int i = 0; i < n_prereqs; i++) {
            GI.BaseInfo? field = null;

            GI.BaseInfo prereq = info.get_prerequisite (i);
            GI.InfoType prereq_type = prereq.get_type ();

            if (prereq_type == GI.InfoType.OBJECT) {
                field = object_info_find_field ((GI.ObjectInfo) prereq, name, lookup);
            }
            else if (prereq_type == GI.InfoType.INTERFACE) {
                field = iface_info_find_field ((GI.InterfaceInfo) prereq, name, lookup);
            }

            if (field != null) return field;
        }
        return null;
    }
}
