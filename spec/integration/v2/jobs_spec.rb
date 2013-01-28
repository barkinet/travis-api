require 'spec_helper'

describe 'Jobs' do
  let!(:jobs) {[
    FactoryGirl.create(:test, :number => '3.1', :queue => 'builds.common'),
    FactoryGirl.create(:test, :number => '3.2', :queue => 'builds.common')
  ]}
  let(:job) { jobs.first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it '/jobs?queue=builds.common' do
    response = get '/jobs', { queue: 'builds.common' }, headers
    response.should deliver_json_for(Job.queued('builds.common'), version: 'v2')
  end

  it '/jobs/:id' do
    response = get "/jobs/#{job.id}", {}, headers
    response.should deliver_json_for(job, version: 'v2')
  end

  context 'GET /jobs/:job_id/log.txt' do
    it 'returns log for a job' do
      job.log.update_attributes!(content: 'the log')
      response = get "/jobs/#{job.id}/log.txt", {}, headers
      response.should deliver_as_txt('the log', version: 'v2')
    end

    context 'when log is archived' do
      it 'redirects to archive' do
        job.log.update_attributes!(content: 'the log', archived_at: Time.now, archive_verified: true)
        response = get "/jobs/#{job.id}/log.txt", {}, headers
        response.should redirect_to("https://archive.travis-ci.org/jobs/#{job.id}/log.txt")
      end
    end

    context 'when log is missing' do
      it 'redirects to archive' do
        job.log.destroy
        response = get "/jobs/#{job.id}/log.txt", {}, headers
        response.should redirect_to("https://archive.travis-ci.org/jobs/#{job.id}/log.txt")
      end
    end
  end
end
