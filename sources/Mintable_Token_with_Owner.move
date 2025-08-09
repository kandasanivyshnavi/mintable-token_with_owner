module mintable_token_with_owner::MintableToken {
    use aptos_framework::signer;
    use std::string::String;
    use aptos_framework::coin::{Self, MintCapability, BurnCapability};

    /// Error codes
    const E_NOT_OWNER: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;

    /// Token information struct
    struct TokenInfo has key {
        name: String,
        symbol: String,
        decimals: u8,
        mint_cap: MintCapability<MintableToken>,
        burn_cap: BurnCapability<MintableToken>,
    }

    /// The token type
    struct MintableToken {}

    /// Initialize the token (can only be called once by the owner)
    public fun initialize_token(
        owner: &signer,
        name: String,
        symbol: String,
        decimals: u8
    ) {
        let owner_addr = signer::address_of(owner);
        
        // Ensure token hasn't been initialized yet
        assert!(!exists<TokenInfo>(owner_addr), E_ALREADY_INITIALIZED);

        // Initialize the coin
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MintableToken>(
            owner,
            name,
            symbol,
            decimals,
            true, // monitor_supply
        );

        // Destroy freeze capability as we don't need it
        coin::destroy_freeze_cap(freeze_cap);

        // Store token info with mint and burn capabilities
        let token_info = TokenInfo {
            name,
            symbol,
            decimals,
            mint_cap,
            burn_cap,
        };
        
        move_to(owner, token_info);
    }

    /// Mint new tokens (only owner can call this)
    public fun mint_tokens(
        owner: &signer,
        to: address,
        amount: u64
    ) acquires TokenInfo {
        let owner_addr = signer::address_of(owner);
        
        // Ensure only owner can mint
        assert!(exists<TokenInfo>(owner_addr), E_NOT_OWNER);
        
        let token_info = borrow_global<TokenInfo>(owner_addr);
        
        // Mint coins and deposit to recipient
        let minted_coins = coin::mint<MintableToken>(amount, &token_info.mint_cap);
        coin::deposit<MintableToken>(to, minted_coins);
    }
}