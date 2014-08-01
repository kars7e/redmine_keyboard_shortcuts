require_dependency 'issues_controller'

module IssuesControllerPatch

  def self.included(base) # :nodoc:

    base.send(:include, InstanceMethods)

    base.module_eval do
      alias_method_chain :retrieve_previous_and_next_issue_ids,:parent
      before_filter :authorize, :except => [:index, :get_next_subissue, :get_prev_subissue]

    end
  end
  module InstanceMethods
    def retrieve_previous_and_next_issue_ids_with_parent
      retrieve_query_from_session
      if @query
        query = @query.dup
        query.add_available_filter 'parent_id', { :type => :integer, :name => 'Zagadnienie nadrzedne' }
        if @issue.parent
          query.add_filter('parent_id', '=', [@issue.parent.id.to_s])
        else
          query.add_filter('parent_id', '!*')
        end
        sort_init(query.sort_criteria.empty? ? [['id', 'desc']] : query.sort_criteria)
        sort_update(query.sortable_columns, 'issues_index_sort')
        limit = 500
        issue_ids = query.issue_ids(:order => sort_clause, :limit => (limit + 1), :include => [:assigned_to, :tracker, :priority, :category, :fixed_version])
        if (idx = issue_ids.index(@issue.id)) && idx < limit
          if issue_ids.size < 500
            @issue_position = idx + 1
            @issue_count = issue_ids.size
          end
          @prev_issue_id = issue_ids[idx - 1] if idx > 0
          @next_issue_id = issue_ids[idx + 1] if idx < (issue_ids.size - 1)
        end
      end
    end
  end

end

Rails.configuration.to_prepare do
  # This tells the Redmine version's controller to include the module from the file above.
  IssuesController.send(:include,IssuesControllerPatch)
end
