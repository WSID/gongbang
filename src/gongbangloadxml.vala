namespace Gongbang {
    /**
     * Loads Graph from xml.
     */
    public Graph load_xml (InputStream stream, Cancellable? cancel = null) throws IOError, MarkupError {
        return new Graph ();
    }

    public Graph load_xml_string (string xml) throws MarkupError {
        return new Graph ();
    }

    public Graph load_xml_file (File file, Cancellable? cancel = null) throws Error {
        return load_xml (file.read(cancel), cancel);
    }
}
