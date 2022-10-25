contract;

use std::{
    storage::StorageVec,
    storage::StorageMap,
    identity::Identity,
    constants::BASE_ASSET_ID,
    option::Option,
    chain::auth::{AuthError, msg_sender},
    context::{call_frames::msg_asset_id, msg_amount, this_balance},
    token::transfer,
};

pub struct Project {
    projectId: u64,
    price: u64,
    ownerAddress: Identity,
    // use IPFS CID here?
    metadata: str[5],
}

pub enum InvalidError {
    IncorrectAssetId: (),
    NotEnoughTokens: (),
}

storage {
    // map of project ids to a vector of ratings
    // ratings: StorageMap<u64, Vec<u64>> = StorageMap {},
    buyers: StorageMap<Identity, Vec<u64>> = StorageMap {},
    projectListings: StorageVec<Project> = StorageVec {},
    // commissionPercent: u64 = 420,
    // owner: Identity =  Identity::Address(ADDRESS_HERE);
}

abi WebGum {
    #[storage(read, write)]
    fn list_project(price: u64, metadata: str[5]) -> Project;

    // #[storage(read, write)]
    // fn update_project(projectId: u64, price: u64, metadata: str[50]) -> Project;

    #[storage(read, write)]
    fn buy_project(projectId: u64) -> Identity;

    // #[storage(read, write)]
    // fn reviewProject(projectId: u64, rating: u64);

    #[storage(read)]
    fn get_project(projectId: u64) -> Project;

    #[storage(read)]
    fn get_buyer_list_length(buyer: Identity) -> u64;

    #[storage(read)]
    fn has_bought_project(projectId: u64, wallet: Identity) -> bool;

    // #[storage(read, write)]
    // fn update_owner(identity: Identity);

}

impl WebGum for Contract {
    #[storage(read, write)]
    fn list_project(price: u64, metadata: str[5]) -> Project{
        let index = storage.projectListings.len();
        let sender: Result<Identity, AuthError> = msg_sender();

        let newProject =  Project {
            projectId: index,
            price: price,
            ownerAddress: sender.unwrap(),
            metadata: metadata,
        };

        storage.projectListings.push(newProject);

        return newProject
    }

    // #[storage(read, write)]
    // fn update_project(projectId: u64, price: u64, metadata: str[50]) -> Project{
    //     let project = storage.projectListings.get(projectId).unwrap()
        
    // }

    #[storage(read, write)]
    fn buy_project(projectId: u64) -> Identity {
        let asset_id = msg_asset_id();
        let amount = msg_amount();

        let project: Project = storage.projectListings.get(projectId).unwrap();

        // require payment
        require(asset_id == BASE_ASSET_ID, InvalidError::IncorrectAssetId);
        require(amount >= project.price, InvalidError::NotEnoughTokens);
        
        let sender: Result<Identity, AuthError> = msg_sender();

        // // check if buyer already exists
        let mut existing: Vec<u64> = storage.buyers.get(sender.unwrap());

        // add msg sender to buyer list
        if existing.len() < 1 {
            let mut buyerList = ~Vec::new();
            buyerList.push(projectId);
            storage.buyers.insert(sender.unwrap(), buyerList);
        } else {
            existing.push(projectId);
            storage.buyers.insert(sender.unwrap(), existing);
        }

        // // TO DO: add commission
        // //send the payout
        // this isn't working 
        // transfer(amount, asset_id, project.ownerAddress);

        let id: Identity = sender.unwrap();

        return id;
    }

    // #[storage(read, write)]
    // fn reviewProject(projectId: u64, rating: u64){

    // }

    #[storage(read)]
    fn get_project(projectId: u64) -> Project{
        let project = storage.projectListings.get(projectId).unwrap();
        return project
    }

    #[storage(read)]
    fn get_buyer_list_length(buyer: Identity) -> u64{
        let sender: Result<Identity, AuthError> = msg_sender();
        let buyer_list: Vec<u64> = storage.buyers.get(sender.unwrap());
        return buyer_list.len()
    }

    #[storage(read)]
    fn has_bought_project(projectId: u64, wallet: Identity) -> bool{
         let sender: Result<Identity, AuthError> = msg_sender();

        let existing: Vec<u64> = storage.buyers.get(sender.unwrap());

        let mut i = 0;
        while i < existing.len() {
            let project = existing.get(i).unwrap();
            if project == projectId {
                return true;
            }
            i += 1;
        }

        return false;

    }

    // #[storage(read, write)]
    //  fn update_owner(identity: Identity) {
    //     storage.owner = Option::Some(identity);
    // }
}
