package main

/* Imports
* 4 utility libraries for handling bytes, reading and writing JSON,
formatting, and string manipulation
* 2 specific Hyperledger Fabric specific libraries for Smart Contracts
*/
import (
	//"bytes"
	//"strconv"

	"bytes"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
)

// Define the Smart Contract structure
type SmartContract struct {
}

type Feriado struct {
	TipoRequisicao string `json:"tipoRequisicao"`
	Data           string `json:"data"`
	Situacao       string `json:"situacao"`
	TipoFeriado    string `json:"tipoFeriado"`
	Descricao      string `json:"descricao"`
}

func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {

	// Retrieve the requested Smart Contract function and arguments
	function, args := APIstub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger
	if function == "consultar" {
		return s.queryFeriado(APIstub, args)
	} else if function == "initLedger" {
		return s.initLedger(APIstub)
	} else if function == "incluir" {
		return s.recordFeriado(APIstub, args)
	} else if function == "alterar" {
		return s.changeFeriado(APIstub, args)
	} else if function == "mudarSituacao" {
		return s.changeSituacao(APIstub, args)
	} else if function == "queryAllFeriado" {
		return s.queryAllFeriado(APIstub)
	}
	return shim.Error("Invalid Smart Contract function name.")
}

func (s *SmartContract) queryFeriado(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	feriadoAsBytes, _ := APIstub.GetState(args[0])
	if feriadoAsBytes == nil {
		return shim.Error("Could not locate feriado -- queryFeriado function")
	}
	return shim.Success(feriadoAsBytes)
}

func (s *SmartContract) initLedger(APIstub shim.ChaincodeStubInterface) sc.Response {
	feriados := []Feriado{
		Feriado{TipoRequisicao: "efetivar", Data: "2018/07/09", Situacao: "Ativo(a)", TipoFeriado: "Estadual", Descricao: "Revolução Constitucionalista de 1932"},
		Feriado{TipoRequisicao: "efetivar", Data: "2018/09/07", Situacao: "Ativo(a)", TipoFeriado: "Nacional", Descricao: "Independência"},
		Feriado{TipoRequisicao: "efetivar", Data: "2018/01/25", Situacao: "Ativo(a)", TipoFeriado: "Municipal", Descricao: "Aniversário da Cidade de São Paulo"},
		Feriado{TipoRequisicao: "efetivar", Data: "2018/11/15", Situacao: "Ativo(a)", TipoFeriado: "Nacional", Descricao: "Proclamação da República"},
	}

	i := 0
	for i < len(feriados) {
		feriadoAsBytes, _ := json.Marshal(feriados[i])
		APIstub.PutState(generateID(feriados[i].Data), feriadoAsBytes)
		fmt.Println("Added", feriados[i])
		i = i + 1
	}

	return shim.Success(nil)
}

func generateID(data string) string {
	return strings.Replace(data, "/", "", -1)
}

func (s *SmartContract) recordFeriado(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 5 {
		return shim.Error("Incorrect number of arguments. Expecting 5")
	}

	var feriado = Feriado{Data: args[0], Descricao: args[1], Situacao: args[2], TipoFeriado: args[3], TipoRequisicao: args[4]}

	feriadoAsBytes, _ := json.Marshal(feriado)
	err := APIstub.PutState(generateID(args[0]), feriadoAsBytes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to record feriado: %s", args[0]))
	}

	// buffer is a JSON array containing the key of recorded Feriado.
	var buffer bytes.Buffer

	buffer.WriteString("{\"Key\":")
	buffer.WriteString("\"")
	buffer.WriteString(generateID(args[0]))
	buffer.WriteString("\"")
	buffer.WriteString("}")

	return shim.Success(buffer.Bytes())
}

func (s *SmartContract) changeFeriado(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 5 {
		return shim.Error("Incorrect number of arguments. Expecting 5")
	}

	feriadoAsBytes, _ := APIstub.GetState(generateID(args[0]))
	if feriadoAsBytes == nil {
		return shim.Error("Could not locate feriado -- changeFeriado function")
	}
	feriado := Feriado{}

	json.Unmarshal(feriadoAsBytes, &feriado)

	feriado.Descricao = args[1]
	feriado.Situacao = args[2]
	feriado.TipoFeriado = args[3]
	feriado.TipoRequisicao = args[4]

	feriadoAsBytes, _ = json.Marshal(feriado)
	err := APIstub.PutState(generateID(args[0]), feriadoAsBytes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to update feriado: %s", args[0]))
	}

	var buffer bytes.Buffer

	buffer.WriteString("{\"Key\":")
	buffer.WriteString("\"")
	buffer.WriteString(generateID(args[0]))
	buffer.WriteString("\"")
	buffer.WriteString("}")

	return shim.Success(buffer.Bytes())
}

func (s *SmartContract) changeSituacao(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	feriadoAsBytes, _ := APIstub.GetState(generateID(args[0]))
	if feriadoAsBytes == nil {
		return shim.Error("Could not locate feriado -- changeSituacao function")
	}
	feriado := Feriado{}

	json.Unmarshal(feriadoAsBytes, &feriado)

	if args[1] == "ativar" {
		feriado.Situacao = "Ativo(a)"
	} else if args[1] == "inativar" {
		feriado.Situacao = "Inativo(a)"
	}

	feriadoAsBytes, _ = json.Marshal(feriado)
	err := APIstub.PutState(generateID(args[0]), feriadoAsBytes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to update feriado: %s", args[0]))
	}
	var buffer bytes.Buffer

	buffer.WriteString("{\"Key\":")
	buffer.WriteString("\"")
	buffer.WriteString(generateID(args[0]))
	buffer.WriteString("\"")
	buffer.WriteString("}")

	return shim.Success(buffer.Bytes())
}

func (s *SmartContract) queryAllFeriado(APIstub shim.ChaincodeStubInterface) sc.Response {

	startKey := "0"
	endKey := "999"

	resultsIterator, err := APIstub.GetStateByRange(startKey, endKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add comma before array members,suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- queryAllFeriado:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}

func main() {

	// Create a new Smart Contract
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
