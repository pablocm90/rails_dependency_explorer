# frozen_string_literal: true

module RailsDependencyExplorer
  module Analysis
    # Interface for analyzers that work with graph structures and dependencies.
    # Provides common graph analysis utilities and structure analysis capabilities.
    # Analyzers that deal with dependency graphs, cycles, or graph traversal should include this interface.
    module GraphAnalyzerInterface
      def self.included(base)
        # Module included callback - can be used for validation or setup
      end
      # Builds an adjacency list representation from dependency data
      # @param dependency_data [Hash] The dependency data to convert
      # @return [Hash] Adjacency list where keys are nodes and values are arrays of connected nodes
      def build_adjacency_list(dependency_data = @dependency_data)
        return {} if dependency_data.nil? || dependency_data.empty?
        
        adjacency_list = {}
        
        dependency_data.each do |class_name, dependencies|
          adjacency_list[class_name] ||= []
          
          dependencies.each do |dependency_hash|
            dependency_hash.each do |dependency_name, _methods|
              adjacency_list[class_name] << dependency_name unless adjacency_list[class_name].include?(dependency_name)
              adjacency_list[dependency_name] ||= []
            end
          end
        end
        
        adjacency_list
      end

      # Analyzes the structure of the dependency graph
      # @return [Hash] Graph structure information including nodes, edges, components, cycles
      def analyze_graph_structure
        adjacency_list = build_adjacency_list
        
        return {
          nodes: 0,
          edges: 0,
          components: 0,
          has_cycles: false,
          strongly_connected_components: []
        } if adjacency_list.empty?
        
        nodes = adjacency_list.keys.size
        edges = adjacency_list.values.flatten.size
        
        # Detect cycles using DFS
        has_cycles = detect_cycles(adjacency_list)
        
        # Find strongly connected components
        scc = find_strongly_connected_components(adjacency_list)

        # Count weakly connected components (treat graph as undirected for component counting)
        components = count_weakly_connected_components(adjacency_list)
        
        {
          nodes: nodes,
          edges: edges,
          components: components,
          has_cycles: has_cycles,
          strongly_connected_components: scc
        }
      end

      private

      # Detects cycles in the graph using DFS
      # @param adjacency_list [Hash] The adjacency list representation
      # @return [Boolean] True if cycles are detected
      def detect_cycles(adjacency_list)
        visited = {}
        rec_stack = {}
        
        adjacency_list.keys.each do |node|
          next if visited[node]
          
          return true if dfs_cycle_detection(node, adjacency_list, visited, rec_stack)
        end
        
        false
      end

      # DFS helper for cycle detection
      def dfs_cycle_detection(node, adjacency_list, visited, rec_stack)
        visited[node] = true
        rec_stack[node] = true
        
        adjacency_list[node].each do |neighbor|
          if !visited[neighbor]
            return true if dfs_cycle_detection(neighbor, adjacency_list, visited, rec_stack)
          elsif rec_stack[neighbor]
            return true
          end
        end
        
        rec_stack[node] = false
        false
      end

      # Finds strongly connected components using simplified algorithm
      # @param adjacency_list [Hash] The adjacency list representation
      # @return [Array<Array<String>>] Array of strongly connected components
      def find_strongly_connected_components(adjacency_list)
        visited = {}
        components = []

        adjacency_list.keys.each do |node|
          next if visited[node]

          # For each unvisited node, find its strongly connected component
          component = find_scc_from_node(node, adjacency_list, visited)
          components << component unless component.empty?
        end

        components
      end

      # Find strongly connected component starting from a node
      def find_scc_from_node(start_node, adjacency_list, visited)
        # Simple approach: find nodes reachable from start_node and that can reach start_node
        forward_reachable = {}
        dfs_forward(start_node, adjacency_list, forward_reachable)

        # Build reverse graph
        reverse_graph = build_reverse_graph(adjacency_list)

        # Find nodes that can reach start_node (by going backward from start_node)
        backward_reachable = {}
        dfs_forward(start_node, reverse_graph, backward_reachable)

        # SCC is intersection of forward and backward reachable
        scc = forward_reachable.keys & backward_reachable.keys

        # Mark all nodes in this SCC as visited
        scc.each { |node| visited[node] = true }

        scc
      end

      # DFS to find all reachable nodes
      def dfs_forward(node, adjacency_list, reachable)
        return if reachable[node]

        reachable[node] = true
        adjacency_list[node]&.each do |neighbor|
          dfs_forward(neighbor, adjacency_list, reachable)
        end
      end

      # Build reverse graph
      def build_reverse_graph(adjacency_list)
        reverse_graph = {}

        # Initialize all nodes
        adjacency_list.keys.each { |node| reverse_graph[node] = [] }

        # Add reverse edges
        adjacency_list.each do |node, neighbors|
          neighbors.each do |neighbor|
            reverse_graph[neighbor] ||= []
            reverse_graph[neighbor] << node
          end
        end

        reverse_graph
      end

      # Count weakly connected components (treat graph as undirected)
      def count_weakly_connected_components(adjacency_list)
        visited = {}
        component_count = 0

        adjacency_list.keys.each do |node|
          next if visited[node]

          # Start a new component
          component_count += 1
          dfs_undirected(node, adjacency_list, visited)
        end

        component_count
      end

      # DFS treating graph as undirected
      def dfs_undirected(node, adjacency_list, visited)
        visited[node] = true

        # Visit all neighbors (outgoing edges)
        adjacency_list[node]&.each do |neighbor|
          next if visited[neighbor]
          dfs_undirected(neighbor, adjacency_list, visited)
        end

        # Visit all nodes that point to this node (incoming edges)
        adjacency_list.each do |other_node, neighbors|
          next if visited[other_node]
          next unless neighbors.include?(node)

          dfs_undirected(other_node, adjacency_list, visited)
        end
      end
    end
  end
end
