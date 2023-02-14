//
//  ChaosSaverShaders.metal
//  ChaosSaver
//
//  Created by Charles Liske on 2/12/23.
//
#include <metal_stdlib>
#define SIGMA 10.0
#define RHO 28.0
#define BETA 2.666666666666667
#define T 0.01
#define NUM_POINTS_IN_TRAIL 1000



using namespace metal;

typedef float3 RBEntry;

struct RBHeader {
    device RBEntry* buf;
    uint last;
    uint first;
    uint count;
    uint zeroIndex;
    
    void push(RBEntry entry) {
        uint l = last;
        last++;
        if (l == count - 1 + zeroIndex) {
            last = zeroIndex;
        }
        first = l;
        buf[l] = entry;
    };
    
    RBEntry pop() {
        uint f = first;
        first--;
        if (f == zeroIndex) {
            first = count - 1 + zeroIndex;
        }
        return buf[f];
    };
    void set_buf(device RBEntry* newBuf) {
        buf = newBuf;
    }
    RBEntry readfirst() {
        return buf[first];
    };
    RBEntry operator[] (int index) {
        return buf[((int)first - index) % (count - 1)];
    };
};


struct CMRSplineSegment {
    float2 a;
    float2 b;
    float2 c;
    float2 d;
    CMRSplineSegment(float2 p0, float2 p1, float2 p2, float2 p3) {
        float t01 = pow(distance(p0, p1), 0.5);
        float t12 = pow(distance(p1, p2), 0.5);
        float t23 = pow(distance(p2, p3), 0.5);
        
        float2 m1 = (p2 - p1 + t12 * ((p1 - p0) / t01 - (p2 - p0) / (t01 + t12)));
        float2 m2 = (p2 - p1 + t12 * ((p3 - p2) / t23 - (p3 - p1) / (t12 + t23)));
        
        a = 2.0f * (p1 - p2) + m1 + m2;
        b = -3.0f * (p1 - p2) - m1 - m1 - m2;
        c = m1;
        d = m2;
    };
    // at^3 + bt^2 + ct + d
    float2 interp(float t) {
        float t2 = t * t;
        return a * t2 * t +
        b * t2 +
        c * t +
        d;
    }
    // 3at^2 + 2bt + c
    float2 norm(float t) {
        float2 tangent = 3 * a * t * t +
        2 * b * t +
        c;
        return float2(tangent.y, -tangent.x);
    }
};





struct VertexIn {
    float2 position[[attribute(0)]];
};
struct VertexOut {
    float4 position [[position]];
};
struct PointTracker {
    packed_float3 positions[NUM_POINTS_IN_TRAIL];
};

float3 compute_der(float3 in)
{
    return float3(SIGMA * (in.y - in.x), in.x * (RHO - in.z), in.x * in.y - BETA * in.z);
}





vertex VertexOut vert_main(VertexIn in [[stage_in]])
{
    VertexOut out;
    out.position = float4(in.position, 1.0);
    return out;
}

fragment float4 frag_main(VertexOut in [[stage_in]])
{
    return in.position / 1000.0;
}
kernel void lorentz_init(
                         device RBEntry* buf [[buffer(1)]],
                         device RBHeader* headers [[buffer(0)]],
                         uint index [[ thread_position_in_grid ]]
                         )
{
    RBHeader header = headers[index];
    header.set_buf(buf);
    headers[index] = header;
}
kernel void update_lorentz(
                           device RBEntry* buf [[buffer(1)]],
                           device RBHeader* headers [[buffer(0)]],
                           uint index [[ thread_position_in_grid ]]
                           )
{
    RBHeader header = headers[index];
    float3 pos = header.readfirst();
    header.push(pos + T * compute_der(pos));
    headers[index] = header;
}




