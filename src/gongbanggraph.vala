namespace Gongbang {

    /**
     * A node representation.
     */
    public abstract class Node {}

    public class NodeValue: Node{
        public Value value;

        public NodeValue (Value value) {
            this.value = value;
        }
    }

    public class NodeStruct: Node{
        public Type type;
        public HashTable<string, int32> members;

        public NodeStruct (Type type) {
            this.type = type;
            members = new HashTable<string, int32> (string.hash, str_equal);
        }
    }

    public class NodeList: Node{
        public Type type;
        public GenericArray<int32> items;

        public NodeList (Type type) {
            this.type = type;
            items = new GenericArray<int32> ();
        }
    }

    public class NodeMap: Node{
        public Type type;
        public HashTable<int32, int32> items;

        public NodeMap (Type type) {
            this.type = type;
            items = new HashTable<int32, int32> (direct_hash, direct_equal);
        }
    }

    /**
     * A graph representation.
     */
    public class Graph: GLib.Object {
        private HashTable<int32, Node?> nodes = new HashTable<int32, Node?> (direct_hash, direct_equal);
        private int32 last_node = 1;

        public uint n_nodes {
            get {
                return nodes.length;
            }
        }

        /**
         * Adds node.
         *
         * @param node A Node, or null for placeholder.
         */
        public int32 add (Node? node) {
            nodes[last_node] = node;
            return last_node++;
        }

        public bool remove (int32 node_id) {
            return nodes.remove (node_id);
        }

        public new Node? get (int32 id) {
            return nodes[id];
        }
    }
}
