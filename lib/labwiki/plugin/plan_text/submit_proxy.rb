require 'labwiki/plugin/plan_text/abstract_publish_proxy'

module LabWiki::Plugin::PlanText
  class SubmitProxy < AbstractPublishProxy

    def publish(content_proxy, opts)
      submission_repo = opts[:repo_iterator].find { |v| v.name == :submission }

      raise StandardError, 'Submission repo NOT found' if submission_repo.nil?

      opts[:url].gsub(/:/, '/')
      student_id = opts[:url].split(':')[0]

      submission_url = submission_repo.get_url_for_path((['wiki', student_id] + opts[:url].split('/')[1..-1]).join('/'))
      submission_repo.write(submission_url, content_proxy.content, "#{student_id} submitted: #{submission_url}")

      # Append to submission history page
      # Student, submitted file, when
      record_url = submission_repo.get_url_for_path('wiki/submission.md')

      new_entry = "\n#{student_id} submitted [#{submission_url}](lw:plan:#{submission_url}) at #{Time.now.to_s}\n"

      to_write = if submission_repo.exist?(record_url)
                   submission_repo.read(record_url) + new_entry
                 else
                   "# Submission\n" + new_entry
                 end

      submission_repo.write(record_url, to_write, "New submission")
    end
  end
end
