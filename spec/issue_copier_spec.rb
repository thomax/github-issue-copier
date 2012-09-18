require 'issue_copier'

describe IssueCopier do

  let(:params) {
    {
      :username => "thomax",
      :password => "zecret",
      :source_org => "old-org",
      :destination_org => "new-org",
      :source_repo => "old-repo",
      :destination_repo => "new-repo"
    }
  }

  subject {
    IssueCopier.new(params)
  }

  it "has issues" do
    issues = subject.get_issues
    issues.should_not eq nil
  end

  it "finds comments on an issue with comments" do
    issues = subject.get_issues
    puts issues
    comments = subject.get_comments_on(issues.first)
    comments.should_not eq nil
  end

  it "imports issues" do
    issues = subject.get_issues
    puts issues.map{|issue| issue.number}
    issues.each do |issue|
      puts "[#{issue.number}] #{issue.title} -- #{issue.assignee}"
      subject.import_issue(issue)
    end
  end


end