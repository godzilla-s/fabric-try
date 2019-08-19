package example;

import org.hyperledger.fabric.shim.Chaincode;
import org.hyperledger.fabric.shim.ChaincodeStub;

import java.util.HashMap;

public interface Asset {
    public String className();
    public HashMap<String,String> ownerShip();
    public Chaincode.Response invoke(ChaincodeStub stub, Parameter params) throws Exception;
}
