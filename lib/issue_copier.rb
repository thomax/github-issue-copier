require 'github_api'

class IssueCopier

  attr_reader :source_client, :destination_client, :username, :password, :source_repo, :destination_repo, :source_org, :destination_org

  def initialize(params)
    @username = params[:username]
    @password = params[:password]
    @source_org = params[:source_org]
    @destination_org = params[:destination_org]
    @source_repo = params[:source_repo]
    @destination_repo = params[:destination_repo]
    @source_client = Github.new(:basic_auth => "#{username}:#{password}", :org => source_org, :user => source_org)
    @destination_client = Github.new(:basic_auth => "#{username}:#{password}", :org => destination_client, :user => destination_client)
  end

  def get_labels(repo)
    source_client.issues.labels.list(source_org, repo)
  end

  def get_issues
    source_client.issues.list_repo(source_org, source_repo)
  end

  def get_comments_on(issue)
    comments = []
    if issue.comments? && issue.comments > 0
      comments = source_client.issues.comments.all(source_org, source_repo, issue.number)
    end
    comments
  end

  def import_labels(labels)
    labels = labels_to_create(labels, get_labels(destination_repo))
    labels.each do |label|
      label_params = {
        'name' => label.name,
        'color' => label.color
      }
      destination_client.issues.labels.create(destination_org, destination_repo, label_params)
    end
  end

  def import_comments(old_issue, new_issue)
    comments = get_comments_on(old_issue)
    comments.each do |comment|
      comment_params = {
        'body' => comment_body_with_source_link(comment, old_issue.number)
      }
      destination_client.issues.comments.create(destination_org, destination_repo, new_issue.number, comment_params)
    end
  end

  def import_issue(old_issue)
    # make sure the labels exist
    import_labels(old_issue.labels)

    # post the issue
    assignee = old_issue.assignee ? old_issue.assignee.login : nil
    issue_params = {
      'title' => old_issue.title,
      'body' => old_issue.body,
      'assignee' => assignee,
      'milestone' => old_issue.milestone,
      'labels' => old_issue.labels.map{ |label| label.name }
    }
    begin
      new_issue = destination_client.issues.create(destination_org, destination_repo, issue_params)
      puts "Added issue #{new_issue.title}"
    rescue StandardError => e
      puts "Failed to create issue [#{old_issue.number}] #{old_issue.title}): #{issue_params}"
      puts "#{e.message}"
      puts "***************"
    end

    # add comments
    import_comments(old_issue, new_issue) if new_issue
  end


  def comment_body_with_source_link(comment, issue_number)
    # convert the api link to a usable link
    url = comment['url'].sub('//api.', '//').sub('repos/', '').sub('comments/', "#{issue_number}#issuecomment-")
    "Copied from #{url}\n#{comment['body']}"
  end

  def labels_to_create(new_labels, existing_labels)
    new_label_names = new_labels.map{|label| label.name}
    existing_label_names = existing_labels.map{|label| label.name}
    names_to_create = new_label_names - existing_label_names
    return new_labels.select{|label| names_to_create.include?(label.name) }
  end

end
