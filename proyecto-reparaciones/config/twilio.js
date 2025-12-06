const twilio = require('twilio');
const config = require('./config');

const twilioClient = twilio(
    process.env.TWILIO_ACCOUNT_SID ,
    process.env.TWILIO_AUTH_TOKEN 
);

const twilioWhatsAppNumber = process.env.TWILIO_WHATSAPP_NUMBER || '+14155238886';

module.exports = {
    twilioClient,
    twilioWhatsAppNumber,
    sendWhatsAppMessage: async (to, body) => {
        try {
            const message = await twilioClient.messages.create({
                from: `whatsapp:${twilioWhatsAppNumber}`,
                to: `whatsapp:${to}`,
                body: body
            });
            
            return { success: true, messageId: message.sid };
        } catch (error) {
            console.error('Twilio error:', error);
            return { success: false, error: error.message };
        }
    }
};