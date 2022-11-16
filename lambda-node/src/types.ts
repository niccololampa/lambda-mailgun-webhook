export interface MailGunHookSignature {
    token: string
    timestamp: string
    signature: string
}

export interface MailGunHookEventData {
    id: string
    event: string
}

export interface MailGunHook {
    signature: MailGunHookSignature
    "event-data": MailGunHookEventData
}

export interface APIGatewayEvent {
    body: string
}
