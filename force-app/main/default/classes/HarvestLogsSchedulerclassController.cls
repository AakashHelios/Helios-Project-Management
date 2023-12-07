global class HarvestLogsSchedulerclassController  implements Schedulable  {
global void execute(SchedulableContext sc) {
        // Instantiate the batch class and start the batch job
        harvestlogSchedulerclass batchJob = new harvestlogSchedulerclass();
        Database.executeBatch(batchJob);
        System.debug('batchJob'+batchJob);
    }
}