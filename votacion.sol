//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10 ;

contract Votacion {
    struct vote{
        address voterAddress; //Dirección del votante
        bool choice; //Voto: Falso o Verdadero
    }

    struct voter{
        string voterName; //Nombre del votante
        bool voted; //Indica si ya ha votado o no
    }
    
    mapping(uint => vote) private votes;
    mapping(address => voter) public voterRegister;
    
    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;
    address public ballotOfficialAddress;      
    string public ballotOfficialName;
    string public proposal;
    
    enum State { Created, Voting, Ended }
    
    State public state;
    
    event voterAdded(address voter); //Indica que se agregó un votante
    event voteStarted(); //Indica que la votación comenzó (estado = Voting)
    event voteEnded(uint finalResult); //Indica que la votación finalizó                                                                  //(estado = Ended)
    event voteDone(address voter); //Indica que el votante votó

    modifier onlyOfficial() { //Verifica que el invocador sea el presidente
        require(msg.sender ==ballotOfficialAddress);
        _;    
    }

	modifier inState(State _state) { //Verifica un estado
    	require(state == _state);
        _;
    }
    
    constructor( //Parámetros: nombre del presidente y texto de la propuesta
            string memory _ballotOfficialName, 
            string memory _proposal) public 
    {
            ballotOfficialAddress = msg.sender; //Dirección del invocador
            ballotOfficialName = _ballotOfficialName; 
            proposal = _proposal;  
            state = State.Created; //Se pone el estado de votación en Created
    }

    function addVoter(address _voterAddress, string memory _voterName) public
            inState(State.Created) //Requisito: el estado de la  votación debe ser Created
            onlyOfficial //Requisito: solo el presidente puede registrar votantes
    {
		voter memory v; //Variable de tipo voter
        v.voterName = _voterName; //Nombre del votante
        v.voted = false; //Se indica que no ha votado
        voterRegister[_voterAddress] = v; //Se lleva el votante al mapping
        totalVoter++; //Se aumenta el número de votantes registrados
        emit voterAdded(_voterAddress); //Se emite este evento (votante agregado)
    } 
    
    function startVote() public
        inState(State.Created) //Requisito: el estado de la  votación debe ser Created
        onlyOfficial //Requisito: solo el presidente puede iniciar la votación   
    {
        state = State.Voting; //Se pone el estado de votación en Voting    
        emit voteStarted(); //Se emite este evento (la votación comenzó)
    }   

    function doVote(bool _choice) public
            inState(State.Voting) //Requisito: el estado de la  votación debe ser Voting
            returns (bool voted) //Retorno de la función: true indica que
                                                //el votante estaba inscrito y que no había votado
    {
    	bool found = false;
           
        if (bytes(voterRegister[msg.sender].voterName).length != 0 
            && !voterRegister[msg.sender].voted){
        	voterRegister[msg.sender].voted = true; //Indica que el votante 
                                                                                        //acaba de votar
            vote memory v; //Variable de tipo vote
            v.voterAddress = msg.sender; //Dirección del votante
            v.choice = _choice; //Elección del votante (o sea, su voto)
            if (_choice){ //Verifica si el voto fue true
            	countResult++; //Se aumenta el número de votos que han sido true
            }
            votes[totalVote] = v; //Se lleva el voto al mapping en la pos. totalVote
            totalVote++; //Se aumenta el número de votos que hay hasta ahora
            found = true; //Indica que el votante acaba de votar
        }
        emit voteDone(msg.sender); //Se emite este evento (el votante votó)
        return found;
    }
        
    function endVote() public
        inState(State.Voting) //Requisito: el estado de la  votación debe ser Voting
        onlyOfficial //Requisito: solo el presidente puede finalizar la votación
    {
        state = State.Ended; //Se pone el estado de votación en Ended   
        finalResult = countResult; //Número total (definitivo) de votos que fueron true
                      //se copian de la vble. privada countResult a la vble pública finalResult
        emit voteEnded(finalResult); //Se emite este evento (la votación finalizó)
    }
}





