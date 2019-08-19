package org.hyperledger.fabric;

import com.alibaba.fastjson.JSONObject;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;

import java.util.List;

public class Example extends ChaincodeBase {

    private static Log logger = LogFactory.getLog(Example.class);

    @Override
    public Response init(ChaincodeStub stub) {
        try {
            logger.info("chaincode init");
            stub.putStringState("a", "1000");
            stub.putStringState("b", "2500");
            return newSuccessResponse();
        } catch (Throwable e) {
            return newErrorResponse(e);
        }
    }

    @Override
    public Response invoke(ChaincodeStub stub) {
        try {
            logger.info("chaincode invoke");
            List<String> args = stub.getStringArgs();
            String inArgs = args.get(0);
            logger.info("args: " + inArgs);
            JSONObject json = JSONObject.parseObject(inArgs);
            String func = json.getString("function");
            JSONObject params = json.getJSONObject("args");
            if (params.isEmpty()) {
                return newErrorResponse("empty arguments");
            }
            logger.info("function args: " + params.toJSONString());
            if (func.equals("save")) {
                String id = params.getString("id");
                if (id.equals("")) {
                    System.out.println("id is empty");
                    return newErrorResponse("id is empty");
                }
                logger.info("put:" + id + ";" + params.toJSONString());
                stub.putStringState(id, params.toJSONString());
                stub.putStringState("name", "zhuweijin");
                String a = stub.getStringState("a");
                String b = stub.getStringState("b");
                System.out.println("test value: "+a + "; "+ b);
            } else if (func.equals("get")) {
                String a = stub.getStringState("a");
                String b = stub.getStringState("b");
                System.out.println("test value: "+a + "; "+ b);
                String id = params.getString("id");
                if (id.equals("")) {
                    System.out.println("id is empty");
                    return newErrorResponse("id is empty");
                }
                logger.info("get:" + id);
                String val = stub.getStringState(id);
                System.out.println("get value:" + val);
                String name = stub.getStringState("name");
                System.out.println("==> test get name:" + name);
            } else {
                return newErrorResponse("not found function");
            }
            return newSuccessResponse("success");
        } catch (Throwable e) {
            return newErrorResponse(e);
        }
    }

    public static void main(String []args) {
        Example example = new Example();
        example.start(args);
    }
}
