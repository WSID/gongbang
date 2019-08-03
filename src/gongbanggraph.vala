namespace Gongbang {

    /**
     * A node representation.
     */
    public abstract class Node {}

    public class NodeValue {
        public Value value;
    }

    public class NodeStruct {
        public HashTable<string, int32> members;
    }

    public class NodeList {
        public GenericArray<int32> items;
    }

    public class NodeMap {
        public HashTable<int32, int32> items;
    }

    /**
     * A graph representation.
     */
    public class Graph: GLib.Object {
        private HashTable<int32, Node?> nodes;
        private int32 last_node = 1;

        /**
         * Adds node.
         *
         * @param node A Node, or null for placeholder.
         */
        public int32 add_node (Node? node) {
            nodes[last_node] = node;
            return last_node++;
        }

        public bool remove_node (int32 node_id) {
            return nodes.remove (node_id);
        }
    }
}
