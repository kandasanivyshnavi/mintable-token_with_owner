module mintable_token_with_owner::MintableToken {
    use aptos_framework::signer;
    use std::string::String;
    use aptos_framework::coin::{Self, MintCapability, BurnCapability};

  
    const E_NOT_OWNER: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;

   
    struct TokenInfo has key {
        name: String,
        symbol: String,
        decimals: u8,
        mint_cap: MintCapability<MintableToken>,
        burn_cap: BurnCapability<MintableToken>,
    }

 
    struct MintableToken {}

    
    public fun initialize_token(
        owner: &signer,
        name: String,
        symbol: String,
        decimals: u8
    ) {
        let owner_addr = signer::address_of(owner);
        
        assert!(!exists<TokenInfo>(owner_addr), E_ALREADY_INITIALIZED);

        
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MintableToken>(
            owner,
            name,
            symbol,
            decimals,
            true, // monitor_supply
        );
   coin::destroy_freeze_cap(freeze_cap);

        
        let token_info = TokenInfo {
            name,
            symbol,
            decimals,
            mint_cap,
            burn_cap,
        };
        
        move_to(owner, token_info);
    }

    
    public fun mint_tokens(
        owner: &signer,
        to: address,
        amount: u64
    ) acquires TokenInfo {
        let owner_addr = signer::address_of(owner);
        
      
        assert!(exists<TokenInfo>(owner_addr), E_NOT_OWNER);
        
        let token_info = borrow_global<TokenInfo>(owner_addr);
        
        
        let minted_coins = coin::mint<MintableToken>(amount, &token_info.mint_cap);
        coin::deposit<MintableToken>(to, minted_coins);
    }

}

