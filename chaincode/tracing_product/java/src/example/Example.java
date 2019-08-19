package example;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import io.netty.handler.ssl.OpenSsl;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.protos.msp.Identities;


import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Example extends ChaincodeBase {
    private static Log logger = LogFactory.getLog(Example.class);
    private HashMap<String, Asset> assets;
    private HashMap<String, Participant> participants;

    Example() {
        this.assets = new HashMap<String, Asset>();
        this.participants = new HashMap<String, Participant>();
    }

    private void registerAsset(Asset asset) {
        assets.put(asset.className(), asset);
    }

    private void registerParticipant(Participant participant) {
        participants.put(participant.className(), participant);
    }

    @Override
    public Response init(ChaincodeStub stub) {
        try {
            logger.info("chaincode init");
            return new Response(Response.Status.SUCCESS, "success", null);
        } catch (Throwable e) {
            return new Response(Response.Status.ERROR_THRESHOLD, e.getMessage(), null);
        }
    }

    @Override
    public Response invoke(ChaincodeStub stub) {
        try {
            logger.info("chaincode invoke");
            List<String> inArgs = stub.getStringArgs();
            String value = inArgs.get(0);
            logger.info("args:" + value);
            JSONObject obj = JSON.parseObject(value);
            String className = obj.getString("class");
            String funcName = obj.getString("function");
            JSONObject args = obj.getJSONObject("args");
            Asset asset = assets.get(className);
            if (asset == null) {
                return new Response(Response.Status.ERROR_THRESHOLD, "not found asset", null);
            }

            Identities.SerializedIdentity id = Identities.SerializedIdentity.parseFrom(stub.getCreator());
            String mspId = id.getMspid();
            logger.info("get msp ==>:" + mspId);
            HashMap<String,String> ownership = new HashMap<String,String>();
            for(Map.Entry<String,String> e: asset.ownerShip().entrySet()) {
                String key = e.getKey();
                Participant p = participants.get(key);
                String rw = e.getValue();
                logger.info("ownership: " + key + "; " + rw);
                ownership.put(p.mspID(), rw);
            }
            Parameter params = new Parameter(funcName, asset, mspId, ownership, args);
            return asset.invoke(stub, params);
        } catch (Throwable e) {
            logger.error(e);
            return new Response(Response.Status.ERROR_THRESHOLD, e.getMessage(), null);
        }
    }

    public static void main(String[] args) {
        System.out.println("OpenSSL avaliable: " + OpenSsl.isAvailable());
        Example example = new Example();
        example.registerAsset(new FarmPig());
        example.registerParticipant(new Farm());
        example.registerParticipant(new Slaughter());
        example.start(args);
    }
}
