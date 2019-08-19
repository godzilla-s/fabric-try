package org.hyperledger.fabric.example;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import io.netty.handler.ssl.OpenSsl;
import org.apache.commons.lang3.StringUtils;
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
        this.assets = new HashMap<>();
        this.participants = new HashMap<>();
    }

    private void addAsset(Asset asset) {
        assets.put(asset.className(), asset);
    }

    private void addParticipant(Participant participant) {
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
            List<byte[]> inArgs =  stub.getArgs();
            String value = new String(inArgs.get(0));
            logger.info("args:" + value);
            JSONObject obj = JSON.parseObject(value);
            String className = obj.getString("class");
            String funcName = obj.getString("function");
            if (StringUtils.isNotBlank(funcName)) {
                new Response(Response.Status.ERROR_THRESHOLD, "function is empty", null);
            }
            JSONObject args = obj.getJSONObject("args");
            Asset asset = assets.get(className);
            if (asset == null) {
                return new Response(Response.Status.ERROR_THRESHOLD, "not found asset", null);
            }

            // 获取MspID
            Identities.SerializedIdentity id = Identities.SerializedIdentity.parseFrom(stub.getCreator());
            String mspId = id.getMspid();
            logger.info("get msp ==>:" + mspId);
            HashMap<String,String> ownership = new HashMap<String,String>();
            HashMap<String,String> map = asset.ownerShip();
            for(Map.Entry<String,String> item:  map.entrySet()) {
                String key = item.getKey();
                String val = item.getValue();
                Participant p = participants.get(key);
                if (p == null) {
                    return new Response(Response.Status.ERROR_THRESHOLD, "not found participant", null);
                }
                logger.info("ownership:" + key +";" + val + "; msp:" + p.mspID());
                ownership.put(p.mspID(), val);
            }
            logger.info("function name:" + funcName);
            Parameter params = new Parameter(stub, funcName, asset, mspId, ownership, args);
            return asset.invoke(params);
        } catch (Throwable e) {
            logger.error(e);
            return new Response(Response.Status.ERROR_THRESHOLD, e.getMessage(), null);
        }
    }

    public static void main(String[] args) {
        System.out.println("OpenSSL avaliable: " + OpenSsl.isAvailable());
        Example example = new Example();
        example.addAsset(new FarmPig());
        example.addParticipant(new Farm());
        example.addParticipant(new Slaughter());
        example.start(args);
    }
}
