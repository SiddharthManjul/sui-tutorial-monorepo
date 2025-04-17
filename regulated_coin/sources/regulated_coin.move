module regulated_coin::regulated_coin;
    use sui::coin;
    use sui::balance::Balance;
    use sui::balance;

    #[test_only]
    use sui::test_scenario::{Self};
    #[test_only]
    use sui::test_utils::assert_eq;

    public struct REGULATED_COIN has drop {}

    public struct Coin<phantom T> has key, store {
        id: UID,
        balance: sui::balance::Balance<T>,
    }

    public struct TreasuryCap<phantom T> has key, store {
        id: UID,
        total_supply: sui::balance::Supply<T>,
    }

    fun init(otw: REGULATED_COIN, ctx: &mut TxContext) {
    // Creates a new currency using `create_currency`, but with an extra capability that
    // allows for specific addresses to have their coins frozen. Those addresses cannot interact
    // with the coin as input objects.
    let (treasury_cap, deny_cap, meta_data) = coin::create_regulated_currency_v2(
        otw,
        5,
        b"$TABLE",
        b"RegulaCoin",
        b"Example Regulated Coin",
        option::none(),
        true,
        ctx,
    );

    let sender = tx_context::sender(ctx);
    transfer::public_transfer(treasury_cap, sender);
    transfer::public_transfer(deny_cap, sender);
    transfer::public_transfer(meta_data, sender);
}

/// Create a coin worth `value` and increase the total supply
/// in `cap` accordingly.
public fun mint<T>(cap: &mut TreasuryCap<T>, value: u64, ctx: &mut TxContext): Coin<T> {
    Coin {
        id: object::new(ctx),
        balance: cap.total_supply.increase_supply(value),
    }
}

/// Mint some amount of T as a `Balance` and increase the total
/// supply in `cap` accordingly.
/// Aborts if `value` + `cap.total_supply` >= U64_MAX
public fun mint_balance<T>(cap: &mut TreasuryCap<T>, value: u64): Balance<T> {
    cap.total_supply.increase_supply(value)
}

// === Entrypoints ===

/// Mint `amount` of `Coin` and send it to `recipient`. Invokes `mint()`.
public entry fun mint_and_transfer<T>(
    c: &mut TreasuryCap<T>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext,
) {
    transfer::public_transfer(mint(c, amount, ctx), recipient)
}

/// Destroy the coin `c` and decrease the total supply in `cap`
/// accordingly.
public entry fun burn<T>(cap: &mut TreasuryCap<T>, c: Coin<T>): u64 {
    let Coin { id, balance } = c;
    id.delete();
    cap.total_supply.decrease_supply(balance)
}

/// Get the value of a coin.
public fun value<T>(coin: &Coin<T>): u64 {
    balance::value(&coin.balance)
}

#[test_only]
    /// Special init function that's only available in tests
    public fun test_init(ctx: &mut TxContext) {
        init(REGULATED_COIN {}, ctx)
    }

#[test]
    fun test_init_and_mint() {
        // Set up the test scenario
        let admin = @0xAD;
        let mut scenario = test_scenario::begin(admin);
        
        // Test package initialization
        {
            test_init(test_scenario::ctx(&mut scenario));
        };
        
        // Test that the admin received the treasury cap
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<REGULATED_COIN>>(&scenario);
            
            // Test minting to the admin
            let minted_coin = mint(&mut treasury_cap, 1000, test_scenario::ctx(&mut scenario));
            assert_eq(value(&minted_coin), 1000);
            
            // Transfer the minted coin to self for this test
            transfer::public_transfer(minted_coin, admin);
            
            // Return the treasury cap to the object store
            test_scenario::return_to_sender(&scenario, treasury_cap);
        };
        
        test_scenario::end(scenario);
    }