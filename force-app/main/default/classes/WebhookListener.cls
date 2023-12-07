@RestResource(urlMapping='/webhookListener/*')
global with sharing class WebhookListener {

    @HttpPost
    global static void handlenotification(){
        try{
            RestRequest request = RestContext.request;
            RestResponse response = RestContext.response;
            System.debug('Received request: ' + request);

            // Fetch the body
            Blob requestBodyBlob = request.requestBody;
            String requestBodyString = requestBodyBlob.toString();
            System.debug('Received JSON in request body: ' + requestBodyString);

            // Parse the JSON
            if (!String.isEmpty(requestBodyString)) {
                JSONParser parser = JSON.createParser(requestBodyString);
                while (parser.nextToken() != null) {
                    // Process JSON tokens here
                    System.debug(parser.getText());
                }
            } else {
                System.debug('Empty request body');
            }
        } catch(Exception e){
            System.debug('Exception occurred: ' + e.getMessage());
        }
    }
}