package org.hyperledger.fabric.example;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class Slaughter implements Participant {
    @Override
    public String className() { return "participant.Slaughter"; }

    @Override
    public String mspID() { return "Org2MSP"; }
}
