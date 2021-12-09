//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

contract Votacion {
    enum Category {
        HighDisagree,
        Disagree,
        Neutral,
        Agree,
        HighAgree
    }

    struct vote {
        address voterAddress; //Dirección del votante
        uint256 counter; // contador de cuantas veces a votado
        Proposal choice;
        Category category; //Voto: Altamente deacuerdo, Deacuerdo
    }

    struct voter {
        string voterName; //Nombre del votante
        bool voted; //Indica si ya ha votado o no
    }

    struct counterVote {
        int256 highDisagree;
        int256 disagree;
        int256 neutral;
        int256 agree;
        int256 highAgree;
    }

    mapping(Proposal => counterVote) private counterVotes;
    mapping(address => vote) private votes;
    mapping(address => voter) public voterRegister;

    uint256 private countResult = 0;
    uint256 public finalResult = 0;
    uint256 public totalVoter = 0;
    uint256 public totalVote = 0;
    address payable public president;
    string public ballotOfficialName;
    string public proposal_1;
    string public proposal_2;
    address payable public vicePresident;
    address public startedVote;
    uint256 public ethers;

    enum State {
        Created,
        Voting,
        Ended
    }
    enum Proposal {
        First,
        Second
    }

    State public state;

    event voterAdded(address voter); //Indica que se agregó un votante
    event voteStarted(); //Indica que la votación comenzó (estado = Voting)
    event voteEnded(uint256 finalResult); //Indica que la votación finalizó                                                                  //(estado = Ended)
    event voteDone(address voter); //Indica que el votante votó

    modifier onlyOfficial() {
        //Verifica que el invocador sea el presidente o vicepresidente
        require(msg.sender == president || msg.sender == vicePresident);
        _;
    }

    modifier onlyWhoEnd() {
        require(msg.sender != startedVote);
        _;
    }

    modifier inState(State _state) {
        //Verifica un estado
        require(state == _state);
        _;
    }

    constructor(
        //Parámetros: nombre del presidente y texto de la propuesta
        string memory _ballotOfficialName,
        address payable _vicePresident,
        string memory _proposal_1,
        string memory _proposal_2
    ) public {
        require(_vicePresident != msg.sender);
        president = msg.sender; //Dirección del invocador
        ballotOfficialName = _ballotOfficialName;
        proposal_1 = _proposal_1;
        proposal_2 = _proposal_2;
        vicePresident = _vicePresident;
        state = State.Created; //Se pone el estado de votación en Created
        ethers = 0;

        counterVotes[Proposal.First].highDisagree = 0;
        counterVotes[Proposal.First].disagree = 0;
        counterVotes[Proposal.First].neutral = 0;
        counterVotes[Proposal.First].agree = 0;
        counterVotes[Proposal.First].highAgree = 0;

        counterVotes[Proposal.Second].highDisagree = 0;
        counterVotes[Proposal.Second].disagree = 0;
        counterVotes[Proposal.Second].neutral = 0;
        counterVotes[Proposal.Second].agree = 0;
        counterVotes[Proposal.Second].highAgree = 0;
    }

    function addVoter(address _voterAddress, string memory _voterName)
        public
        inState(State.Created) //Requisito: el estado de la  votación debe ser Created
        onlyOfficial //Requisito: solo el presidente puede registrar votantes
    {
        require(vicePresident != _voterAddress);
        require(president != _voterAddress);

        voter memory v; //Variable de tipo voter
        v.voterName = _voterName; //Nombre del votante
        v.voted = false; //Se indica que no ha votado
        voterRegister[_voterAddress] = v; //Se lleva el votante al mapping
        totalVoter++; //Se aumenta el número de votantes registrados
        emit voterAdded(_voterAddress); //Se emite este evento (votante agregado)
    }

    function startVote()
        public
        inState(State.Created) //Requisito: el estado de la  votación debe ser Created
        onlyOfficial //Requisito: solo el presidente o el vicepresidente pueden iniciar la votación
    {
        state = State.Voting; //Se pone el estado de votación en Voting
        startedVote = msg.sender;
        emit voteStarted(); //Se emite este evento (la votación comenzó)
    }

    function doVote(Proposal _choice, Category _category)
        public
        payable
        inState(State.Voting) //Requisito: el estado de la  votación debe ser Voting
        returns (
            bool voted //Retorno de la función: true indica que
        )
    //el votante estaba inscrito y que no había votado
    {
        bool found = false;
        vote memory v; //Variable de tipo vote

        if (
            bytes(voterRegister[msg.sender].voterName).length != 0 &&
            !voterRegister[msg.sender].voted
        ) {
            voterRegister[msg.sender].voted = true; //Indica que el votante acaba de votar
            v.voterAddress = msg.sender; //Dirección del votante
            v.choice = _choice; //Elección del votante (o sea, su voto)
            v.category = _category;
            v.counter = 0;
            updateCounterVote(_choice, _category, 1); //aumentamos el contador de votos por propuesta y categoria
            votes[msg.sender] = v; //Se lleva el voto al mapping en la pos. totalVote
            totalVote++; //Se aumenta el número de votos que hay hasta ahora
            found = true; //Indica que el votante acaba de votar
            emit voteDone(msg.sender); //Se emite este evento (el votante votó)
        } else {
            v = votes[msg.sender];
            if (msg.value == v.counter + 1) {
            	updateCounterVote(_choice, v.category, -1); // descantamos la categoria anterior
            	updateCounterVote(_choice, _category, 1); //aumentamos la nueva categoria elegida
            	v.category = _category; // Actualiza a la nueva categoria
            	v.counter = v.counter + 1; // aumenta los votos que ha hecho el votante
           	 ethers = ethers + msg.value; //se acomula el pago de los que votan por segunda vez o mas
            	votes[msg.sender] = v; // se actualiza el voto
            	emit voteDone(msg.sender); //Se emite este evento (el votante votó)
        	} else {
            	msg.sender.transfer(msg.value); //retorna el pago erroneo que hizo el votante
        	}
        }

        return found;
    }

    function updateCounterVote(
        Proposal _proposal,
        Category _category,
        int256 _inc
    ) private {
        if (_category == Category.HighDisagree) {
            counterVotes[_proposal].highDisagree =
                counterVotes[_proposal].highDisagree +
                _inc;
        } else if (_category == Category.Disagree) {
            counterVotes[_proposal].disagree =
                counterVotes[_proposal].disagree +
                _inc;
        } else if (_category == Category.Neutral) {
            counterVotes[_proposal].neutral =
                counterVotes[_proposal].neutral +
                _inc;
        } else if (_category == Category.HighAgree) {
            counterVotes[_proposal].highAgree =
                counterVotes[_proposal].highAgree +
                _inc;
        } else if (_category == Category.Agree) {
            counterVotes[_proposal].agree =
                counterVotes[_proposal].agree +
                _inc;
        }
    }

    function endVote()
        public
        inState(State.Voting) //Requisito: el estado de la  votación debe ser Voting
        onlyOfficial //Requisito: solo el presidente o el vicepresidente pueden finalizar la votación
        onlyWhoEnd
    {
        state = State.Ended; //Se pone el estado de votación en Ended
        finalResult = countResult; //Número total (definitivo) de votos que fueron true
        //se copian de la vble. privada countResult a la vble pública finalResult
        emit voteEnded(finalResult); //Se emite este evento (la votación finalizó)
        uint comision = ethers/2;
        president.transfer(comision);
        vicePresident.transfer(comision);
    }
}
