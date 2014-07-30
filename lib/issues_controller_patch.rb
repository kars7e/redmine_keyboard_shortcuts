require_dependency 'issues_controller'

module IssuesControllerPatch

  def self.included(base) # :nodoc:

    base.send(:include, InstanceMethods)

    base.module_eval do
      alias_method_chain :update,:parent
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
        #@query.delete_available_filter 'parent_id'
      end

      # if @issue.parent
      #   issues_higher = Issue.where('parent_id = ? AND id > ?', @issue.parent_id, @issue.id).order('id asc')
      #   if issues_higher and issues_higher.length > 0
      #     @next_issue_id = issues_higher[0].id
      #   end
      #   issues_lower = Issue.where('parent_id = ? AND id < ?', @issue.parent_id, @issue.id).order('id asc')
      #   if issues_lower and issues_lower.length > 0
      #     @prev_issue_id  = issues_lower[0].id
      #   end
      #   @issue_position = issues_lower.length + 1
      #   @issue_count = issues_lower.length + issues_higher.length + 1
      # else
      #   retrieve_previous_and_next_issue_ids_without_parent
      # end
    end

    def update_with_parent
      return unless update_issue_from_params
      @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
      saved = false
      begin
        saved = save_issue_with_child_records
      rescue ActiveRecord::StaleObjectError
        @conflict = true
        if params[:last_journal_id]
          @conflict_journals = @issue.journals_after(params[:last_journal_id]).all
          @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
        end
      end

      if saved
        render_attachment_warning_if_needed(@issue)
        flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?
        if params[:redirect_to_parent]
          if (@issue.parent_issue_id)
            redirect_back_or_default issue_path(@issue.parent_issue_id)
          else
            redirect_to project_issues_path(@issue.project)
          end
        else
          respond_to do |format|
            format.html { redirect_back_or_default issue_path(@issue) }
            format.api  { render_api_ok }
          end
        end

      else
        respond_to do |format|
          format.html { render :action => 'edit' }
          format.api  { render_validation_errors(@issue) }
        end
      end
    end
  end

end

Rails.configuration.to_prepare do
  # This tells the Redmine version's controller to include the module from the file above.
  IssuesController.send(:include,IssuesControllerPatch)
end
