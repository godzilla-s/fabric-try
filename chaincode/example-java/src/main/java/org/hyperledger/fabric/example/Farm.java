package org.hyperledger.fabric.example;

import lombok.Getter;
import lombok.Setter;
import org.hyperledger.fabric.shim.Chaincode;
import org.hyperledger.fabric.shim.ChaincodeStub;

@Getter
@Setter
public class Farm implements Participant {
    private String id;
    private String name;

    @Override
    public String className() {
        return "participant.Farm";
    }

    @Override
    public String mspID() {
        return "Org1MSP";
    }
}
