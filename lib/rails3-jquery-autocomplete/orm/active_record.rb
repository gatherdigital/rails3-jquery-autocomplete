module Rails3JQueryAutocomplete
  module Orm
    module ActiveRecord
      def get_autocomplete_order(method, options, model=nil)
        order = options[:order]

        table_prefix = model ? "#{model.table_name}." : ""
        order || "#{table_prefix}#{method} ASC"
      end

      def get_autocomplete_items(parameters)
        model   = parameters[:model]
        term    = parameters[:term]
        method  = parameters[:method]
        options = parameters[:options]
        scopes  = Array(options[:scopes])
        where   = options[:where]
        limit   = get_autocomplete_limit(options)
        order   = get_autocomplete_order(method, options, model)


        items = model.scoped

        scopes.each do |scope|
          if scope.is_a? Proc
            items = scope.call(items, parameters)
          else
            items = items.send(*Array(scope))
          end
        end unless scopes.empty?

        items = items.select(get_autocomplete_select_clause(model, method, options)) unless options[:full_model]
        items = items.where(get_autocomplete_where_clause(model, term, method, options)).
            limit(limit).order(order)
        items = items.where(where) unless where.blank?

        items
      end

      def get_autocomplete_select_clause(model, method, options)
        table_name = model.table_name
        extra_columns =
          if options[:extra_data].nil?
            []
          elsif options[:extra_data].is_a? Hash
            options[:extra_data].keys
          else
            options[:extra_data]
          end
        (["#{table_name}.#{model.primary_key}", "#{table_name}.#{method}"] + extra_columns)
      end

      def get_autocomplete_where_clause(model, term, method, options)
        table_name = model.table_name
        is_full_search = options[:full]
        like_clause = (postgres?(model) ? 'ILIKE' : 'LIKE')
        ["LOWER(#{table_name}.#{method}) #{like_clause} ?", "#{(is_full_search ? '%' : '')}#{term.downcase}%"]
      end

      def postgres?(model)
        # Figure out if this particular model uses the PostgreSQL adapter
        model.connection.class.to_s.match(/PostgreSQLAdapter/)
      end
    end
  end
end
