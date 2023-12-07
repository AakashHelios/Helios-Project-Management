global class ProjectLogsSchedulerclassController implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class and start the batch job
        ProjectLogsSchedulerclass batchJob = new ProjectLogsSchedulerclass();
        Database.executeBatch(batchJob);
        System.debug('batchJob'+batchJob);
    }
    
}