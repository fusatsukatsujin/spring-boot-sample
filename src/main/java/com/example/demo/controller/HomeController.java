package com.example.demo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.PutItemRequest;
import java.util.Map;

@Controller
public class HomeController {
    
    @Autowired
    private DynamoDbClient dynamoDbClient;
    
    @GetMapping("/")
    public String home() {
        return "index";
    }

    @PostMapping("/register")
    public String register() {
        dynamoDbClient.putItem(PutItemRequest.builder()
        .tableName("Users")
        .item(Map.of(
            "id", AttributeValue.builder().s("1").build(),
            "name", AttributeValue.builder().s("John Doe").build()
        ))
        .build());
        return "index";
    }
} 