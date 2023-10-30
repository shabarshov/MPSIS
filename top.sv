module top(
    input logic a,
    input logic b,
    output logic q
);

    logic c;
    
    inv invertor_1(
        .A(a),
        .D(c)
    );
    
    inv invertor_2(
        .A(c & b),
        .D(q)
    );


endmodule
