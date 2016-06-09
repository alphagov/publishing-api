module ExperimentControl
  def experiment_control(name, candidate:)
    start_time = Time.now
    result = yield
    duration = (Time.now - start_time).to_f

    id = SecureRandom.uuid

    ExperimentResultWorker.perform_async(name, id, result, duration, :control)

    candidate_worker = candidate.fetch(:worker)
    candidate_worker.perform_async(*candidate.fetch(:args),
      name: name,
      id: id,
    )

    result
  end
end
