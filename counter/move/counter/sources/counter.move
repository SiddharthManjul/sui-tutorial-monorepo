module counter::counter {
    public struct Counter has key {
        id: UID,
        owner: address,
        count: u64,
    }

    public fun create(ctx: &mut TxContext) {
        transfer::share_object(Counter {
            id: object::new(ctx),
            owner: ctx.sender(),
            value: 0
        })
    }
}