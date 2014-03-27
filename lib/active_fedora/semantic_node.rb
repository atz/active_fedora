module ActiveFedora
  module SemanticNode 
    extend ActiveSupport::Concern

    attr_accessor :relationships_loaded
    attr_accessor :load_from_solr, :subject

    def assert_kind_of(n, o,t)
      raise "Assertion failure: #{n}: #{o} is not of type #{t}" unless o.kind_of?(t)
    end

    def clear_relationships
      @relationships_loaded = false
      @object_relations = nil
    end


    # Add a relationship to the Object.
    # @param [Symbol, String] predicate
    # @param [URI, ActiveFedora::Base] target Either a string URI or an object that is a kind of ActiveFedora::Base 
    # TODO is target ever a AF::Base anymore?
    def add_relationship(predicate, target, literal=false)
      #raise ArgumentError, "predicate must be a symbol. You provided `#{predicate.inspect}'" unless predicate.class.in?([Symbol, String])
      object_relations.add(predicate, target, literal)
    end

    # Clears all relationships with the specified predicate
    # @param predicate
    def clear_relationship(predicate)
      relationships(predicate).each do |target|
        object_relations.delete(predicate, target) 
      end
    end

    # Checks that this object is matches the model class passed in.
    # It requires two steps to pass to return true
    #   1. It has a hasModel relationship of the same model
    #   2. kind_of? returns true for the model passed in
    # This method can most often be used to detect if an object from Fedora that was created
    # with a different model was then used to populate this object.
    # @param [Class] model_class the model class name to check if an object conforms_to that model
    # @return [Boolean] true if this object conforms to the given model name
    def conforms_to?(model_class)
      if self.kind_of?(model_class)
        #check has model and class match
        mod = relationships.first(:predicate=>Predicates.find_graph_predicate(:has_model))
        if mod
          expected = self.class.to_class_uri
          if mod.object.to_s == expected
            return true
          else
            raise "has_model relationship check failed for model #{model_class} raising exception, expected: '#{expected}' actual: '#{mod.object.to_s}'"
          end
        else
          raise "has_model relationship does not exist for model #{model_class} check raising exception"
        end
      else
        raise "kind_of? check failed for model #{model_class}, actual #{self.class} raising exception"
      end
      return false
    end

    #
    # Remove a relationship from the Object.
    # @param predicate
    # @param obj Either a string URI or an object that responds to .pid 
    def remove_relationship(predicate, obj, literal=false)
      object_relations.delete(predicate, obj)
      object_relations.dirty = true
    end

    # If no arguments are supplied, return the whole RDF::Graph.
    # if a predicate is supplied as a parameter, then it returns the result of quering the graph with that predicate
    def relationships(*args)
      load_relationships unless relationships_loaded

      if args.empty?
        raise "Must have uri" unless uri
        return object_relations.to_graph(uri)
      end
      rels = object_relations[args.first] || []
      rels.map {|o| o.respond_to?(:uri) ? o.uri : o }.compact   #TODO, could just return the object
    end

    def load_relationships
      @relationships_loaded = true
      raise "Not implemented: load_relationships"
    end

    def ids_for_outbound(predicate)
      (object_relations[predicate] || []).map do |o|
        o = o.to_s if o.kind_of? RDF::Literal
        o.kind_of?(String) ? self.class.pid_from_uri(o) : o.pid
      end
    end

  end
end
