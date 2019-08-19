package org.hyperledger.fabric.example;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import lombok.Getter;
import lombok.Setter;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.hyperledger.fabric.shim.Chaincode;
import org.hyperledger.fabric.shim.ChaincodeStub;

import java.util.HashMap;

@Getter
@Setter
public class FarmPig implements Asset {
    private String  id;
    private String  farmID;
    private String  quarantineCert;
    private int     quantity;
    private String  batchNo;

    private static Log logger = LogFactory.getLog(FarmPig.class);

    @Override
    public String className() {
        return "asset.FarmPig";
    }

    @Override
    public HashMap<String, String> ownerShip() {
        HashMap<String,String> owner = new HashMap<>();
        owner.put("participant.Farm", "rw");
        owner.put("participant.Slaughter", "r");
        return owner;
    }

    @Override
    public Chaincode.Response invoke(Parameter params) throws Exception {
        try {
            logger.info("invoke:" + params.getFunction());
            switch (params.getFunction()) {
                case "save":
                    return save(params);
                case "query":
                    return query(params);
                case "delete":
                    return delete(params);
                case "update":
                    return update(params);
                case "auth":
                    return auth(params);
                default:
                    return new Chaincode.Response(Chaincode.Response.Status.INTERNAL_SERVER_ERROR, "unknown function ", null);
            }
        } catch (Exception e) {
            throw new Exception(e);
        }
    }

    /***
     * 读写授权*/
    private Chaincode.Response auth(Parameter params) {
        if (!params.isOwnershipWritable()) {
            if (!params.isAuthWritable()) {
                return new Chaincode.Response(1, "no authority to access write", null);
            }
        }
        // TODO
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    private Chaincode.Response unauth(Parameter params) {
        if (!params.isOwnershipWritable()) {
            if (!params.isAuthWritable()) {
                return new Chaincode.Response(1, "no authority to access write", null);
            }
        }
        // TODO
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    /***
     * 存储数据 ***/
    private Chaincode.Response save(Parameter params) {
        logger.info("invoke save function");
        if (!params.isOwnershipWritable()) {
            logger.info("not ownership");
            if (!params.isAuthWritable()) {
                logger.error("no authority to access write");
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access write", null);
            }
        }

        String jsonStr = params.getArgsString();
        System.out.println("json string: " + jsonStr);
        FarmPig farmPig = JSON.parseObject(jsonStr, FarmPig.class);
        System.out.println(farmPig.id);
        System.out.println(farmPig.quarantineCert);
        System.out.println(farmPig.quantity);

        params.getStub().putStringState(farmPig.id, jsonStr);
        // TODO
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    /**
     * 查询数据*/
    private Chaincode.Response query(Parameter params) {
        if (!params.isOwnershipReadable()) {
            if (!params.isAuthReadable()) {
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access read", null);
            }
        }
        String id = params.getString("id");
        if (StringUtils.isAllBlank(id)){
            return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "not found id", null);
        }
        String val = params.getStub().getStringState(id);
        System.out.println("get:" + val + " ; from id:" + id);
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", val.getBytes());
    }

    /**
     * 删除数据**/
    private Chaincode.Response delete(Parameter params) {
        if (!params.isOwnershipWritable()) {
            if (!params.isAuthWritable()) {
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access write", null);
            }
        }
        String id = params.getString("id");
        if (StringUtils.isAllBlank(id)){
            return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "not found id", null);
        }
        params.getStub().delState(id);
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }

    /**
     * 更新数据**/
    private Chaincode.Response update(Parameter params) {
        if (!params.isOwnershipWritable()) {
            if (!params.isAuthWritable()) {
                return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "no authority to access write", null);
            }
        }

        String jsonStr = params.getArgsString();
        FarmPig farmPig = JSON.parseObject(jsonStr, FarmPig.class);
        byte[] data = params.getStub().getState(farmPig.id);
        if (data.length == 0) {
            return new Chaincode.Response(Chaincode.Response.Status.ERROR_THRESHOLD, "not found asset by id", null);
        }

        String saveJSONStr = farmPig.toString();
        params.getStub().putState(farmPig.id, saveJSONStr.getBytes());
        // TODO
        return new Chaincode.Response(Chaincode.Response.Status.SUCCESS, "success", null);
    }
}