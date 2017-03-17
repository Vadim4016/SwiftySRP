//
//  SRPConfigurationBigIntImpl.swift
//  SwiftySRP
//
//  Created by Sergey A. Novitsky on 22/02/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation
import BigInt


/// Implementation: configuration for SRP algorithms (see the spec. above for more information about the meaning of parameters).
struct SRPConfigurationBigIntImpl: SRPConfiguration
{
    /// A large safe prime per SRP spec. (Also see: https://tools.ietf.org/html/rfc5054#appendix-A)
    public var modulus: Data {
        return _N.serialize()
    }
    
    /// A generator modulo N. (Also see: https://tools.ietf.org/html/rfc5054#appendix-A)
    public var generator: Data {
        return _g.serialize()
    }
    
    /// A large safe prime per SRP spec.
    let _N: BigUInt
    
    /// A generator modulo N
    let _g: BigUInt
    
    /// Hash function to be used.
    let digest: DigestFunc
    
    /// Function to calculate HMAC
    let hmac: HMacFunc
    
    /// Custom function to generate 'a'
    let _aFunc: PrivateValueBigIntFunc?
    
    /// Custom function to generate 'b'
    let _bFunc: PrivateValueBigIntFunc?
    
    
    /// Create a configuration with the given parameters.
    ///
    /// - Parameters:
    ///   - N: The modulus (large safe prime) (per SRP spec.)
    ///   - g: The group generator (per SRP spec.)
    ///   - digest: Hash function to be used in intermediate calculations and to derive a single shared key from the shared secret.
    ///   - hmac: HMAC function to be used when deriving multiple shared keys from a single shared secret.
    ///   - aFunc: (ONLY for testing purposes) Custom function to generate the client private value.
    ///   - bFunc: (ONLY for testing purposes) Custom function to generate the server private value.
    init(N: BigUInt,
         g: BigUInt,
         digest: @escaping DigestFunc = SRP.sha256DigestFunc,
         hmac: @escaping HMacFunc = SRP.sha256HMacFunc,
         aFunc: PrivateValueBigIntFunc?,
         bFunc: PrivateValueBigIntFunc?)
    {
        _N = N
        _g = g
        self.digest = digest
        self.hmac = hmac
        _aFunc = aFunc
        _bFunc = bFunc
    }
    
    
    /// Check if configuration is valid.
    /// Currently only requires the size of the prime to be >= 256 and the g to be greater than 1.
    /// - Throws: SRPError if invalid.
    func validate() throws
    {
        guard _N.width >= 256 else { throw SRPError.configurationPrimeTooShort }
        guard _g > 1 else { throw SRPError.configurationGeneratorInvalid }
    }
    
    /// Generate a random private value less than the given value N and at least half the bit size of N
    ///
    /// - Parameter N: The value determining the range of the random value to generate.
    /// - Returns: Randomly generate value.
    public static func generatePrivateValue(N: BigUInt) -> BigUInt
    {
        // Suppose that N is 8 bits wide
        // Then min bits == 4
        let minBits = N.width / 2
        // Smallest number with 4 bits is 2^(4-1) = 8
        let minBitsNumber = BigUInt(2).power(minBits > 0 ? minBits - 1: 0)
        let random = minBitsNumber + BigUInt.randomIntegerLessThan(N - minBitsNumber)
        
        return random
    }
    
    /// Function to calculate parameter a (per SRP spec above)
    func uint_a() -> BigUInt
    {
        if let aFunc = _aFunc
        {
            return aFunc()
        }
        return SRPConfigurationBigIntImpl.generatePrivateValue(N: _N)
    }
    
    /// Function to calculate parameter a (per SRP spec above)
    func clientPrivateValue() -> Data
    {
        return uint_a().serialize()
    }
    
    /// Function to calculate parameter b (per SRP spec above)
    func uint_b() -> BigUInt
    {
        if let bFunc = _bFunc
        {
            return bFunc()
        }
        return SRPConfigurationBigIntImpl.generatePrivateValue(N: _N)
    }
    
    /// Function to calculate parameter b (per SRP spec above)
    func serverPrivateValue() -> Data
    {
        return uint_b().serialize()
    }
}



