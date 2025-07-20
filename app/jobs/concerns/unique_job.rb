# frozen_string_literal: true

module Jobs::Concerns::UniqueJob
  extend ActiveSupport::Concern

  class_methods do
    # For jobs without arguments
    def perform_unique
      return if pending_job_exists?

      perform_later
    end

    # For jobs with arguments
    def perform_unique_with_args(*args)
      return if pending_job_exists?(args)

      perform_later(*args)
    end

    private

    def pending_job_exists?(args = nil)
      query = SolidQueue::Job.where(
        class_name: name,
        status: [:pending, :running]
      )

      if args.present?
        query = query.where(arguments: args)
      end

      query.exists?
    end
  end
end
