pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "./Stoppable.sol";

contract Dapp is Stoppable {

	modifier onlyValidator() {
		require(validators[validatoraddress[msg.sender]].validatorID != 0);
		require(
			(validators[validatoraddress[msg.sender]].lastBlockValidity >= block.number) ||
			(validators[validatoraddress[msg.sender]].lastBlockValidity == 0));
	_;
	}


	// Interfaces
	// Have to to be updated if IStringUtils.sol is updated
	//IStringUtils iStringUtils = IStringUtils(0x95FfDFe74D4e1c30F16eDCe2e3752FAe15d88023);

	 // The base definition of a Validator that can validate some data
	struct Validator {
		address validatorAddress;
		uint validatorID;

		// If set to a value > 0, Validator will not be able to publish data
		// after the specified bloc
		uint lastBlockValidity;
	}

	mapping (address => uint) public validatoraddress;
	mapping (uint => Validator) public validators;

	uint public validatorsCounter = 0;

	 //event AddValidator(uint, address, string, string);
	function addValidator(address _address) notInStoppedState internal {
			require(validators[validatoraddress[_address]].validatorID == 0);

			// Increment counter of validators before issuing a new Validator
			validatorsCounter += 1;
			validatoraddress[_address] = validatorsCounter;

			validators[validatoraddress[_address]].validatorID = validatorsCounter;
			validators[validatoraddress[_address]].validatorAddress = _address;
			validators[validatoraddress[_address]].lastBlockValidity = 0;

			//emit AddValidator(validatorsCounter, _address, _name, _website,
				//_legalReference, _KYB_hash, _logoURL);
	}

	 // The base definition of a database, its address is defined from the mapping
	struct Database {
		string label;
		string databaseHash;
		uint validatorID;
		mapping ( uint => bool) IdValidatorAllowed;

		bool exists;
	}

	function allowValidatorToReadDatabase(address _validatorAddress, string _databaseId) public onlyValidator() returns(uint) {
		require(validators[validatoraddress[_validatorAddress]].validatorID != 0 && databases[_databaseId].exists);
		require(validators[validatoraddress[msg.sender]].validatorID == databases[_databaseId].validatorID);

		databases[_databaseId].IdValidatorAllowed[validators[validatoraddress[_validatorAddress]].validatorID] = true;
	}

	mapping ( string => Database ) databases;
	mapping ( address => string[] ) public databaseIDs;



	// Adds a database to an validator, defined by its id
	function addDatabase (
		string _databaseId,
		string _label,
		string _databaseHash)
		public onlyValidator()
		{
			require(!databases[_databaseId].exists);

			databases[_databaseId] = Database(_label, _databaseHash, validatoraddress[msg.sender], true);
			databaseIDs[msg.sender].push(_databaseId);
	}

	function getDatabaseList(address _validatorAddress) public view returns(string) {
		string memory ids;
		uint lght = databaseIDs[_validatorAddress].length;

		for (uint i = 0; i < lght; i++)
			ids = strConcat(ids, ";", databaseIDs[_validatorAddress][i]);

		return ids;

	}

	function strConcat(string _first, string _second, string _third)
			public pure returns (string){
		bytes memory _bytesFirst = bytes(_first);
		bytes memory _bytesSecond = bytes(_second);
		bytes memory _bytesThird = bytes(_third);
		string memory abc = new string(_bytesFirst.length + _bytesSecond.length + _bytesThird.length);
		bytes memory bytesAbc = bytes(abc);
		uint k = 0;
		for (uint i = 0; i < _bytesFirst.length; i++) bytesAbc[k++] = _bytesFirst[i];
		for (i = 0; i < _bytesSecond.length; i++) bytesAbc[k++] = _bytesSecond[i];
		for (i = 0; i < _bytesThird.length; i++) bytesAbc[k++] = _bytesThird[i];
		return string(bytesAbc);
	}


	function databaseExists(string _databaseId) public view returns(bool) {
		return databases[_databaseId].exists;
	}

	// returns the label of the template defined by templateId for a given issuer
	function getDatabaseLabel(address _validatorAddress, string _databaseId) public view returns (string) {
		require(databases[_databaseId].validatorID == validatoraddress[_validatorAddress]);
		return databases[_databaseId].label;
	}

	// returns the template defined by templateId for a given issuer
	function getDatabase(string _databaseId) public view returns (string) {
		require(databases[_databaseId].validatorID == validatoraddress[msg.sender] ||
			databases[_databaseId].IdValidatorAllowed[validators[validatoraddress[msg.sender]].validatorID] == true);
		return databases[_databaseId].databaseHash;
	}

	function allowValidatorForDays(address _validatorAddress, uint _days) public onlyOwner() {
		if (validators[validatoraddress[_validatorAddress]].validatorID == 0)
			addValidator(_validatorAddress);
		if (validators[validatoraddress[_validatorAddress]].lastBlockValidity <= block.number)
			validators[validatoraddress[_validatorAddress]].lastBlockValidity = now + (_days * 1 days);
		else
			validators[validatoraddress[_validatorAddress]].lastBlockValidity = validators[validatoraddress[_validatorAddress]].lastBlockValidity + (_days * 1 days);
	}

	function allowValidator(address _validatorAddress) public onlyOwner() {
		if (validators[validatoraddress[_validatorAddress]].validatorID == 0)
			addValidator(_validatorAddress);
		validators[validatoraddress[_validatorAddress]].lastBlockValidity = 0;
	}

	function blockValidator(address _validatorAddress) public onlyOwner() {
		if (validators[validatoraddress[_validatorAddress]].validatorID == 0)
			addValidator(_validatorAddress);
		validators[validatoraddress[_validatorAddress]].lastBlockValidity = 1;
	}

	function isValidator(address _validatorAddress) public view returns (bool) {
		if (validators[validatoraddress[_validatorAddress]].validatorID == 0)
			return false;
		else if (validators[validatoraddress[_validatorAddress]].lastBlockValidity < block.number && validators[validatoraddress[_validatorAddress]].lastBlockValidity != 0)
			return false;
		else
			return true;
	}
}
