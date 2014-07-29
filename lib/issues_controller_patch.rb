require_dependency 'issues_controller'

module IssuesControllerPatch

  def self.included(base) # :nodoc:

    base.send(:include, InstanceMethods)

    base.module_eval do
      alias_method_chain :update,:parent
      before_filter :authorize, :except => [:index, :get_next_subissue, :get_prev_subissue]

    end
  end
  module InstanceMethods
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

    def get_next_subissue
      find_issue
      if (@issue.parent)
        issues = Issue.where('parent_id = ? AND id > ?', @issue.parent_id, @issue.id).order('id asc')
        if issues and issues.length > 0
          render :text => issues[0].id
          return
        end
      end
      render :text => ''
    end
    def get_prev_subissue
      find_issue
      if (@issue.parent)
        issues = Issue.where('parent_id = ? AND id < ?', @issue.parent_id, @issue.id).order('id asc')
        if issues and issues.length > 0
          render :text => issues.last.id
          return
        end
      end
      render :text => ''
    end
  end

end

Rails.configuration.to_prepare do
  # This tells the Redmine version's controller to include the module from the file above.
  IssuesController.send(:include,IssuesControllerPatch)
end
