package example;

import com.alibaba.fastjson.JSON;
import lombok.Getter;
import lombok.Setter;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.JSONArray;
import org.apache.commons.lang3.StringUtils;
import org.hyperledger.fabric.shim.Chaincode;
import org.hyperledger.fabric.shim.ChaincodeStub;

import java.util.HashMap;
import java.util.Set;

@Getter
@Setter
public class FarmPig implements Asset {
    private String  id;
    private String  farmID;
    private String  quarantineCert;
    private int     quantity;
    private String  batchNo;

    @Override
    public String className() {
        return "asset.FarmPig";
    }

    @Override
    public HashMap<String, String> ownerShip() {
        HashMap<String,String> owner = new HashMap<String,String>();
        owner.put("participant.Farm", "rw");
        owner.put("participant.Slaughter", "r");
        return owner;
    }

    @Override
    public Chaincode.Response invoke(ChaincodeStub stub, Parameter params) throws Exception {
        try {
            String funcName = params.getFunction();
            if (funcName.equals("save")) {
                return save(stub, params);
            } else if (funcName.equals("get")) {
                return get(stub, params);
            } else if (funcName.equals("delete")) {
                return delete(stub, params);
            } else if (funcName.equals("update")) {
                return update(stub, params);
            } else if (funcName.equals("auth")) {
                return auth(stub, params);
            } else if (funcName.equals("unauth")) {
                return unAuth(stub, params);
            } else {
                return new Chaincode.Response(Chaincode.Response.Status.INTERNAL_SERVER_ERROR, "unknown function ", null);
            }
        } catch (Exception e) {
            throw new Exception(e);
        }
    }

    private Chaincode.Response auth(ChaincodeStub stub, Parameter params) {
        if (!params.isOwnershipWritable(stub)) {
            if (!params.isAuthWritable(stub)) {
                return new Chaincode.Response(1, "no authority to access write", null);
            }
        }

        JSONObject object = params.getArgs();
        for (String key:object.keySet()){
            String val = (String)object.get(key);
            params.setAuth(stub, key, val);
        }

        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    private Chaincode.Response unAuth(ChaincodeStub stub, Parameter params) {
        if (!params.isOwnershipWritable(stub)) {
            if (!params.isAuthWritable(stub)) {
                return new Chaincode.Response(1, "no authority to access write", null);
            }
        }

        JSONArray arr = params.getArgs().getJSONArray("unAuth");
        for(int i=0; i<arr.size(); i++) {
            params.unsetAuth(stub, arr.getString(i));
        }

        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    private Chaincode.Response save(ChaincodeStub stub, Parameter params) {
        if (!params.isOwnershipWritable(stub)) {
            if (!params.isAuthWritable(stub)) {
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access write", null);
            }
        }

        String jsonStr = params.getJSONObjectString();
        FarmPig farmPig = JSON.parseObject(jsonStr, FarmPig.class);
        // TODO
        stub.putState(farmPig.id, jsonStr.getBytes());
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    private Chaincode.Response get(ChaincodeStub stub, Parameter params) {
        if (!params.isOwnershipReadable(stub)) {
            if (!params.isAuthReadable(stub)) {
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access read", null);
            }
        }
        String id = params.getString("id");
        if (!StringUtils.isNotBlank(id)){
            return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "not found id", null);
        }
        byte[] data = stub.getState(id);
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", data);
    }

    private Chaincode.Response delete(ChaincodeStub stub, Parameter params) {
        if (!params.isOwnershipWritable(stub)) {
            if (!params.isAuthWritable(stub)) {
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access write", null);
            }
        }
        String id = params.getString("id");
        if (!StringUtils.isNotBlank(id)){
            return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "not found id", null);
        }
        stub.delState(id);
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    private Chaincode.Response update(ChaincodeStub stub, Parameter params) {
        if (!params.isOwnershipWritable(stub)) {
            if (!params.isAuthWritable(stub)) {
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access write", null);
            }
        }

        String jsonStr = params.getJSONObjectString();
        FarmPig farmPig = JSON.parseObject(jsonStr, FarmPig.class);
        byte[] data = stub.getState(farmPig.id);
        if (data.length == 0) {
            return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "not found asset by id", null);
        }

        String saveJSONStr = farmPig.toString();
        stub.putState(farmPig.id, saveJSONStr.getBytes());
        // TODO
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

}
