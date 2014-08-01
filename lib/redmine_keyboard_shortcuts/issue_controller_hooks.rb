class IssuePermissionSubissueHook < Redmine::Hook::ViewListener
  def controller_issues_new_after_save(context={})
    if context[:params][:redirect_to_parent]
      if (context[:issue].parent_issue_id)
        context[:params][:back_url] = issue_path(context[:issue].parent_issue_id)
      else
        context[:params][:back_url] = project_issues_path(context[:issue].project)
      end
    end
  end
  def controller_issues_edit_after_save(context={})
    if context[:params][:redirect_to_parent]
      if (context[:issue].parent_issue_id)
        context[:params][:back_url] = issue_path(context[:issue].parent_issue_id)
      else
        context[:params][:back_url] = project_issues_path(context[:issue].project)
      end
    end
  end
end